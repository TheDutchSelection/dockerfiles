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
  gzip_vary on;
  gzip_min_length 10240;
  gzip_proxied any;
  gzip_types application/atom+xml application/javascript application/json application/x-javascript application/rdf+xml application/rss+xml application/xml text/css text/javascript text/plain text/xml;

  client_max_body_size 20M;
  large_client_header_buffers 4 32k;
  proxy_buffers 8 16k;
  proxy_buffer_size 32k;
  proxy_read_timeout 1800;
EOM

read -r -d '' reverse_proxy_server_base << EOM || true
  server {
    listen 8080##default_server##;

    server_name ##domain####default_server_name##;
    root ##root##;

    location ^~ /assets/ {
      gzip_static on;
      expires max;
      add_header Access-Control-Allow-Origin "*";
      add_header Cache-Control public;
    }

    location ^~ /cable {
      proxy_pass http://##app##;
      proxy_http_version 1.1;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $http_host;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "Upgrade";
    }

    ##redirects##

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

read -r -d '' standard_server_base << EOM || true
  server {
    listen 8080##default_server##;

    server_name ##domain####default_server_name##;
    root ##root##;

    ##redirects##

    location ~* \.* {
      ##basic_auth##
      gzip_static on;
      expires max;
      ##location_options##
      add_header Access-Control-Allow-Origin "*";
      add_header Cache-Control public;
    }

    try_files \$uri/index.html \$uri =404;
  }
EOM

read -r -d '' server_basic_auth << EOM || true
      auth_basic "Restricted";
      auth_basic_user_file /etc/nginx/.htpasswd;
EOM

create_servers () {
  set -e
  local envs=$(env)

  local servers=""
  while read -r env; do
    server=""
    if [[ "$env" == *"_DOMAIN="* && "$env" == "SERVER_"* ]]; then
      local server_domain_var=$(echo "$env" | awk -F'=' '{print $1}')
      local domain=$(echo "$env" | awk -F'=' '{print $2}')
      local type_var=${server_domain_var/_DOMAIN/_TYPE}
      eval type=\$$type_var
      local root_var=${server_domain_var/_DOMAIN/_ROOT}
      eval root=\$$root_var
      local location_options_var=${server_domain_var/_DOMAIN/_LOCATION_OPTIONS}
      eval location_options=\$$location_options_var
      local is_default_server_var=${server_domain_var/_DOMAIN/_IS_DEFAULT_SERVER}
      eval is_default_server=\$$is_default_server_var
      local redirects_var=${server_domain_var/_DOMAIN/_REDIRECTS}
      eval redirects=\$$redirects_var

      # specific config
      if [[ "$type" == "standard" ]]; then
        local server="$standard_server_base"
      else
        local server="$reverse_proxy_server_base"
        local app=${server_domain_var/SERVER_/}
        local app=${app/_DOMAIN/}
        local app=$(echo "$app" | awk '{print tolower($0)}')

        local server=${server//\#\#app\#\#/"$app"}
      fi

      # replace everything in server
      local server=${server/\#\#domain\#\#/"$domain"}
      local server=${server/\#\#root\#\#/"$root"}

      if [[ -z "$location_options" ]]; then
        local server=${server//\#\#location_options\#\#/}
      else
        local server=${server//\#\#location_options\#\#/"$location_options"}
      fi

      if [[ -z "$is_default_server" ]]; then
        local server=${server//\#\#default_server\#\#/}
        local server=${server//\#\#default_server_name\#\#/}
      else
        local server=${server//\#\#default_server\#\#/" default_server"}
        local server=${server//\#\#default_server_name\#\#/" _"}
      fi

      if [[ -z "$BASIC_AUTH_VALUES" ]]; then
        local server=${server//\#\#basic_auth\#\#/}
      else
        local server=${server//\#\#basic_auth\#\#/"$server_basic_auth"}
      fi

      if [[ -z "$redirects" ]]; then
        local server=${server//\#\#redirects\#\#/}
      else
        local first_redirect=true
        for redirect in $redirects
        do
          local redirect_part_1=$(echo "$redirect" | awk -F'\!\!\#\#' '{print $1}')
          local redirect_part_2=$(echo "$redirect" | awk -F'\!\!\#\#' '{print $2}')
          local redirect_line="rewrite ""$redirect_part_1"" ""$redirect_part_2"" permanent;"

          if [[ "$first_redirect" = true ]]; then
            local redirect_lines="$redirect_line"
            local first_redirect=false
          else
            local redirect_lines="$redirect_lines"$'\n'"$redirect_line"
          fi
        done

        local server=${server//\#\#redirects\#\#/"$redirect_lines"}
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
  local servers=$(create_servers)

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
      local username=$(echo "$basic_auth_value" | awk -F'\!\!\#\#' '{print $1}')
      local password=$(echo "$basic_auth_value" | awk -F'\!\!\#\#' '{print $2}')

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
