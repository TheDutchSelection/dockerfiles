#!/bin/bash
set -e

read -r -d '' nginx_base << EOM || true
daemon off;
worker_processes $WORKER_PROCESSES;

events {
  worker_connections $WORKER_CONNECTIONS;
}

error_log stderr info;

http {
  include       mime.types;
  default_type  application/octet-stream;

  sendfile on;
  tcp_nodelay on;
  tcp_nopush on;

  access_log off;

  keepalive_timeout 20;

  gzip on;
  gzip_disable "MSIE [1-6]\.(?!.*SV1)";
  gzip_types text/plain application/xml text/css text/js text/xml application/x-javascript text/javascript application/json application/xml+rss image/svg+xml image/x-icon;

  client_max_body_size 20M;
  proxy_buffers 8 16k;
  proxy_buffer_size 32k;
EOM

read -r -d '' server_base << EOM || true
  server {
    listen 8080##default_server##;

    server_name ##domain####default_server_name##;
    root ##root##;

    location ^~ /assets/ {
      gzip_static on;
      expires max;
      add_header Cache-Control public;
    }

    try_files \$uri/index.html \$uri @##app##;

    location @##app## {
      ##basic_auth##
      proxy_set_header Host \$http_host;
      ##location_options##
      proxy_redirect off;
      proxy_pass http://##app##;
    }

    error_page 500 502 503 504 /500.html;
    client_max_body_size 4G;
  }
EOM

read -r -d '' server_basic_auth << EOM || true
      auth_basic "Restricted";
      auth_basic_user_file /etc/nginx/.htpasswd;
EOM

read -r -d '' assets_server_base << EOM || true
  server {
    listen 8080;

    server_name ##domain##;
    root ##root##;

    location ^~ /assets/ {
      gzip_static on;
      expires 24h;
      add_header "Access-Control-Allow-Origin" "*";
      add_header Cache-Control public;
    }

    try_files \$uri =404;
  }
EOM

# $1: assets server base
# $2: server base
create_servers () {
  set -e
  local assets_server_base="$1"
  local server_base="$2"
  local envs=$(env)

  local servers=""
  while read -r env; do
    server=""
    if [[ "$env" == *"_ASSETS_DOMAIN="* && "$env" == "SERVER_"* ]]; then
      # we want the SERVER_[APP]_ASSETS_DOMAIN=assets.thedutchselection.com ones
      local server_domain_var=$(echo "$env" | awk -F'=' '{print $1}')
      local domain=$(echo "$env" | awk -F'=' '{print $2}')
      local base="$assets_server_base"
      local root_var=${server_domain_var/_DOMAIN/_ROOT}
      eval root=\$$root_var
      local server=${base/\#\#domain\#\#/"$domain"}
      local server=${server/\#\#root\#\#/"$root"}
    elif [[ "$env" == *"_DOMAIN="* && "$env" == "SERVER_"* ]]; then
      # we want the SERVER_[APP]_DOMAIN=pcnltelecom.tdsapi.com ones
      local server_domain_var=$(echo "$env" | awk -F'=' '{print $1}')
      local domain=$(echo "$env" | awk -F'=' '{print $2}')
      local app=${server_domain_var/SERVER_/}
      local app=${app/_DOMAIN/}
      local app=$(echo "$app" | awk '{print tolower($0)}')
      local base="$server_base"
      local root_var=${server_domain_var/_DOMAIN/_ROOT}
      eval root=\$$root_var
      local location_options_var=${server_domain_var/_DOMAIN/_LOCATION_OPTIONS}
      eval location_options=\$$location_options_var
      local is_default_server_var=${server_domain_var/_DOMAIN/_IS_DEFAULT_SERVER}
      eval is_default_server=\$$is_default_server_var
      local server=${base/\#\#domain\#\#/"$domain"}
      local server=${server/\#\#root\#\#/"$root"}
      local server=${server//\#\#app\#\#/"$app"}
      if [[ -z "$location_options" ]]; then
        local server=${server//\#\#location_options\#\#/}
      else
        local server=${server//\#\#location_options\#\#/"$location_options"}
      fi
      if [[ -z "$BASIC_AUTH_VALUES" ]]; then
        local server=${server//\#\#basic_auth\#\#/}
      else
        local server=${server//\#\#basic_auth\#\#/"$server_basic_auth"}
      fi
      if [[ -z "$is_default_server" ]]; then
        local server=${server//\#\#default_server\#\#/}
        local server=${server//\#\#default_server_name\#\#/}
      else
        local server=${server//\#\#default_server\#\#/" default_server"}
        local server=${server//\#\#default_server_name\#\#/" _"}
      fi
    fi

    if [[ ! -z "$server" ]]; then
      servers="$servers"$'\n'$'\n'"$server"
    fi
  done <<< "$envs"

  echo "$servers"
}

create_upstream_servers () {
  set -e
  local envs=$(env)
  local envs=$(echo "$envs" | sort)

  local upstream_servers=""
  while read -r env; do
    # we want the [APP]_[APP_ID]_HOST_PUBLIC_IP=128.32.14.1 ones
    if [[ "$env" == *"_HOST_PUBLIC_IP="* ]]; then
      local last_app="$app"
      local host_var=$(echo "$env" | awk -F'=' '{print $1}')
      local host=$(echo "$env" | awk -F'=' '{print $2}')
      # remove last 4 parts for APP, ie. PRICE_COMPARATOR_1_HOST_PUBLIC_IP
      local app=$(echo "$host_var" | awk -F'_' '{for(i = 1; i <= NF - 4; i++) printf "%s%s", $i, i == NF -4 ? "" : "_" }')
      local app=$(echo "$app" | awk '{print tolower($0)}')
      local port_var=${host_var/_PUBLIC_IP/_PORT}
      eval port=\$$port_var

      # this works because the envs are alphabetically sorted
      if [[ "$last_app" != "$app" ]]; then
        local upstream_servers="$upstream_servers""$upstream_server"
        if [[ -z "$last_app" ]]; then
          local upstream_server=$'\n'"  upstream $app {"
        else
          local upstream_server=$'\n'"  }"$'\n'$'\n'"  upstream $app {"
        fi
      fi
      local upstream_server="$upstream_server"$'\n'"    server $host:$port;"
    fi
  done <<< "$envs"

  if [[ ! -z "$upstream_server" ]]; then
    local upstream_servers="$upstream_servers""$upstream_server"$'\n'"  }"$'\n'
  fi

  echo "$upstream_servers"
}

# $1: nginx base
# $2: nginx config file
create_config_file () {
  set -e
  local nginx_base="$1"
  local nginx_cnf_file="$2"

  cat /dev/null > "$nginx_cnf_file"

  local upstream_servers=$(create_upstream_servers)
  local servers=$(create_servers "$assets_server_base" "$server_base")

  echo "$nginx_base"$'\n' >> "$nginx_cnf_file"
  echo "$upstream_servers" >> "$nginx_cnf_file"
  echo "$servers" >> "$nginx_cnf_file"
  echo "}" >> "$nginx_cnf_file"
}

create_htpasswd () {
  set -e
  if [[ ! -z "$BASIC_AUTH_VALUES" ]]; then
    local first_user=true
    for basic_auth_value in $BASIC_AUTH_VALUES
    do
      local username=$(echo "$basic_auth_value" | awk -F'\#\#\!\!' '{print $1}')
      local password=$(echo "$basic_auth_value" | awk -F'\#\#\!\!' '{print $2}')

      if [[ "$first_user" = true ]]; then
        htpasswd -cb /etc/nginx/.htpasswd "$username" "$password"
        local first_user=false
      else
        htpasswd -b /etc/nginx/.htpasswd "$username" "$password"
      fi
    done
  fi
}

nginx_cnf_file="/etc/nginx/nginx.conf"

# remove any existing nginx pid
rm -f /var/run/nginx/*

echo "creating htpasswd..."
create_htpasswd

echo "creating $nginx_cnf_file..."
create_config_file "$nginx_base" "$nginx_cnf_file"

echo "starting nginx..."
exec /usr/local/sbin/nginx
