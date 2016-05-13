#!/bin/bash
set -e

trap "echo \"Sending SIGTERM to processes\"; killall -s SIGTERM -w haproxy" SIGTERM

read -r -d '' haproxy_base << EOM || true
global
  maxconn 4096
  user haproxy
  group haproxy
  tune.ssl.default-dh-param 2048
  pidfile /run/haproxy/haproxy.pid

defaults
  mode http
  balance roundrobin
  retries 3
  maxconn 3064
  option redispatch
  option forwardfor
  option http-server-close
  timeout connect 10s
  timeout client 1m
  timeout server 1m
  timeout queue 1m
  timeout http-request 10s
  timeout http-keep-alive 10s
  timeout check 10s
EOM

read -r -d '' haproxy_frontend_http << EOM || true
frontend web-http
  bind *:8080
  reqadd X-Forwarded-Proto:\ http
EOM

read -r -d '' haproxy_frontend_https << EOM || true
frontend web-https
  bind *:8443 ssl crt $CRT_DIRECTORY
  reqadd X-Forwarded-Proto:\ https
EOM

# $1: https_filters
# $2: haproxy backends
frontend_http_filters () {
  set -e
  local https_filters="$1"
  local haproxy_backends="$2"

  local envs=$(env)
  local redirect_list=""
  local acl_list=""
  local backend_list=""

  while read -r env; do
    # we want the FRONTEND_[APP]_DOMAIN="www.thedutchselection.com thedutchselection.com" ones
    if [[ "$env" == *"_DOMAIN="* && "$env" == "FRONTEND_"* ]]; then
      local frontend_domain_var=$(echo "$env" | awk -F'=' '{print $1}')
      local domains=$(echo "$env" | awk -F'=' '{print $2}')
      local app=${frontend_domain_var/FRONTEND_/}
      local app=${app/_DOMAIN/}
      local app=$(echo "$app" | awk '{print tolower($0)}')
      local acl_name="$app"
      local frontend_domain_force_ssl_var=${frontend_domain_var/_DOMAIN/_DOMAIN_FORCE_SSL}
      eval frontend_domain_force_ssl=\$$frontend_domain_force_ssl_var
      local frontend_domain_redirects_var=${frontend_domain_var/_DOMAIN/_DOMAIN_REDIRECTS}
      eval frontend_domain_redirects=\$$frontend_domain_redirects_var

      # only create frontend if app has a backend
      if [[ "$haproxy_backends" == *"$app"* ]]; then
        if [[ ! -z "$frontend_domain_redirects" ]]; then
          for frontend_domain_redirect in $frontend_domain_redirects
          do
            local source=$(echo "$frontend_domain_redirect" | awk -F'\#\#\!\!' '{print $1}')
            local destination=$(echo "$frontend_domain_redirect" | awk -F'\#\#\!\!' '{print $2}')

            local redirect_list="$redirect_list"$'\n'"  redirect prefix http://$destination code 301 if { hdr_beg(host) -i $source }"
          done
        fi

        if [[ "$frontend_domain_force_ssl" == "1" && "$https_filters" != "1" ]]; then
          local redirect_list="$redirect_list"$'\n'"  redirect scheme https code 301 if { hdr_sub(host) -i $domains } !{ ssl_fc }"
        else
          local acl_list="$acl_list"$'\n'"  acl $acl_name hdr_sub(host) -i $domains"
          local backend_list="$backend_list"$'\n'"  use_backend $app if $acl_name"
        fi
      fi
    fi
  done <<< "$envs"

  echo "$redirect_list$acl_list$backend_list"
}

# $1: haproxy frontend http
# $2: haproxy frontend https
# $3: haproxy backends
create_frontend () {
  set -e
  local haproxy_frontend_http="$1"
  local haproxy_frontend_https="$2"
  local haproxy_backends="$3"

  local frontend_https_filters=$(frontend_http_filters "1" "$haproxy_backends")
  local frontend_http_filters=$(frontend_http_filters "0" "$haproxy_backends")
  local frontend="$haproxy_frontend_http""$frontend_http_filters"$'\n'$'\n'"$haproxy_frontend_https""$frontend_https_filters"

  echo "$frontend"
}

create_backends () {
  set -e
  local envs=$(env)
  local envs=$(echo "$envs" | sort)

  local backends=""
  while read -r env; do
    # we want the [APP]_[APP_ID]_HOST_PRIVATE_IP=10.0.4.1 ones
    if [[ "$env" == *"_HOST_PRIVATE_IP="* ]]; then
      local last_app="$app"
      local host_var=$(echo "$env" | awk -F'=' '{print $1}')
      local host=$(echo "$env" | awk -F'=' '{print $2}')
      # remove last 4 parts for APP, ie. NGINX_PRICE_COMPARATOR_1_HOST_PRIVATE_IP
      local app=$(echo "$host_var" | awk -F'_' '{for(i = 1; i <= NF - 4; i++) printf "%s%s", $i, i == NF -4 ? "" : "_" }')
      local app=$(echo "$app" | awk '{print tolower($0)}')
      # print only the 4th part from behind for id
      local app_id=$(echo "$host_var" | awk -F'_' '{print $(NF - 3) }')
      local app_id=$(echo "$app_id" | awk '{print tolower($0)}')
      local port_var=${host_var/_PRIVATE_IP/_PORT}
      eval port=\$$port_var

      # this works because the envs are alphabetically sorted
      if [[ "$last_app" != "$app" ]]; then
        local backends="$backends""$backend"
        if [[ -z "$last_app" ]]; then
          local backend=$'\n'"backend $app"
        else
          local backend=$'\n'$'\n'"backend $app"
        fi
      fi
      local backend="$backend"$'\n'"  server $app_$app_id $host:$port check inter 2000 rise 2 fall 2"
    fi
  done <<< "$envs"

  local backends="$backends""$backend"$'\n'

  echo "$backends"
}

# $1: haproxy base
# $2: haproxy config file
create_config_file () {
  set -e
  local haproxy_base="$1"
  local haproxy_cnf_file="$2"

  cat /dev/null > "$haproxy_cnf_file"

  local backends=$(create_backends)
  local frontend=$(create_frontend "$haproxy_frontend_http" "$haproxy_frontend_https" "$backends")

  echo "$haproxy_base"$'\n' >> "$haproxy_cnf_file"
  echo "$frontend" >> "$haproxy_cnf_file"
  echo "$backends" >> "$haproxy_cnf_file"
}

haproxy_cnf_file="/etc/haproxy/haproxy.cfg"

# remove any existing haproxy pid
rm -f /var/run/haproxy/*

echo "creating $haproxy_cnf_file..."
create_config_file "$haproxy_base" "$haproxy_cnf_file"

echo "starting haproxy..."
/usr/local/sbin/haproxy -f "$haproxy_cnf_file" -db -V &

# wait for the pid of this file to end
wait $!