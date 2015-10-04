#!/bin/bash
set -e

trap "echo \"Sending SIGTERM to processes\"; killall -s SIGTERM -w varnish" SIGTERM

read -r -d '' varnish_base << EOM || true
vcl 4.0;
include "devicedetect.vcl";
import directors;
EOM

read -r -d '' varnish_backend_base << EOM || true
backend ##backend_name## {
  .host = "##host_ip##";
  .port = "##host_port##";
  .probe = {
      .url = "##probe_url##";
      .timeout = 3s;
      .interval = 10s;
      .window = 5;
      .threshold = 3;
  }
}
EOM

read -r -d '' varnish_vcl_backend_response << EOM || true
sub vcl_backend_response {
  set beresp.grace = 6h;

  # set a magicmarker to modify cache-control in vcl_deliver
  if (beresp.ttl > 0s) {
    set beresp.http.magicmarker = "1";
  }

  # modify the Vary header so we vary on the x-ua-device header we added with devicedetect
  if (bereq.http.X-UA-Device) {
    if (!beresp.http.Vary) { # no Vary at all
      set beresp.http.Vary = "X-UA-Device";
    }
    elseif (beresp.http.Vary !~ "X-UA-Device") { # add to existing Vary
      set beresp.http.Vary = beresp.http.Vary + ", X-UA-Device";
    }
  }
  set beresp.http.X-UA-Device = bereq.http.X-UA-Device;
}
EOM

read -r -d '' varnish_vcl_deliver_base << EOM || true
sub vcl_deliver {
  # modify the vary header for caches in the wild
  if ((req.http.X-UA-Device) && (resp.http.Vary)) {
    set resp.http.Vary = regsub(resp.http.Vary, "X-UA-Device", "User-Agent");
  }

  # modify the cache-control, so that it's set right for client cachers
  if (resp.http.magicmarker) {
    unset resp.http.magicmarker;
    set resp.http.X-Varnish-Age = resp.http.age;
    if (##long_term_client_cache_matches##) {
      set resp.http.Cache-Control = "public, max-age=31536000";
    }
    else {
      set resp.http.X-Varnish-Age = resp.http.age;
      set resp.http.Cache-Control = "private, max-age=0, no-cache";
      set resp.http.Age = "0";
    }
  }
}
EOM

read -r -d '' varnish_vcl_recv_ban << EOM || true
  if (req.method == "PUT" && req.http.host ~ ":6081" && req.http.ban-host ~ ".") {
    ban("req.http.host ~ " + req.http.ban-host + " && req.url ~ " + req.url);
    return(synth(999, "Ban added: req.http.host ~ " + req.http.ban-host + " && req.url ~ " + req.url));
  }
EOM

read -r -d '' varnish_vcl_recv_devicedetect << EOM || true
  call devicedetect;

  # normalize devicedetect outcome, because we only want pc, tablet or mobile caches
  if (req.http.X-UA-Device ~ "^mobile") {
    set req.http.X-UA-Device = "mobile";
  }
  elseif (req.http.X-UA-Device ~ "^tablet") {
    set req.http.X-UA-Device = "tablet";
  }
  else {
    set req.http.X-UA-Device = "pc";
  }
EOM

read -r -d '' varnish_vcl_recv_health_check << EOM || true
  if (req.method == "GET" && req.url ~ "/varnish/health_check") {
    return(synth(998, "Up"));
  }
EOM

read -r -d '' varnish_vcl_synth << EOM || true
sub vcl_synth {
  if (resp.status == 999) {
    set resp.status = 200;
    set resp.http.Content-Type = "text/plain; charset=utf-8";
    synthetic("Ban added: req.http.host ~ " + req.http.ban-host + " && req.url ~ " + req.url);
    return(deliver);
  }
  elseif (resp.status == 998) {
    set resp.status = 200;
    set resp.http.Content-Type = "text/plain; charset=utf-8";
    synthetic("Up");
    return(deliver);
  }
}
EOM

create_backends () {
  set -e
  local envs=$(env)
  local envs=$(echo "$envs" | sort)

  local backends=""
  while read -r env; do
    local host=""
    local port=""
    local backend="$varnish_backend_base"
    # we want the [APP]_[APP_ID]_HOST_PRIVATE_IP=10.0.4.1 ones
    if [[ "$env" == *"_HOST_PRIVATE_IP="* ]]; then
      local host_var=$(echo "$env" | awk -F'=' '{print $1}')
      local host=$(echo "$env" | awk -F'=' '{print $2}')
      local port_var=${host_var/_PRIVATE_IP/_PORT}
      eval port=\$$port_var
    # we want the [APP]_[APP_ID]_HOST_PUBLIC_IP=10.0.4.1 ones
    elif [[ "$env" == *"_HOST_PUBLIC_IP="* ]]; then
      # check if we have a private ip available, then we don't want the public one
      local temp_host_var=$(echo "$env" | awk -F'=' '{print $1}')
      local host_private_ip_var=${temp_host_var/_PUBLIC_IP/_PRIVATE_IP}
      eval host_private_ip=\$$host_private_ip_var
      if [[ -z "$host_private_ip" ]]; then
        # we want all PUBLIC_IPS for the specified availability zones
        local host_var=$(echo "$env" | awk -F'=' '{print $1}')
        local host=$(echo "$env" | awk -F'=' '{print $2}')
        local port_var=${host_var/_PUBLIC_IP/_PORT}
        eval port=\$$port_var
      fi
    fi

    if [[ ! -z "$host" && ! -z "$port" ]]; then
      # remove last 4 parts for APP, ie. NGINX_PRICE_COMPARATOR_1_HOST_PRIVATE_IP
      local app_upper=$(echo "$host_var" | awk -F'_' '{for(i = 1; i <= NF - 4; i++) printf "%s%s", $i, i == NF -4 ? "" : "_" }')
      local app=$(echo "$app_upper" | awk '{print tolower($0)}')
      # print only the 4th part from behind for id
      local app_id=$(echo "$host_var" | awk -F'_' '{print $(NF - 3) }')
      local app_id=$(echo "$app_id" | awk '{print tolower($0)}')
      # [APP]_PROBE_PATH
      local probe_path_var="$app_upper""_PROBE_PATH"
      eval probe_path=\$$probe_path_var

      # put backend together
      local backend=${backend//\#\#backend_name\#\#/"$app""_""$app_id"}
      local backend=${backend//\#\#host_ip\#\#/"$host"}
      local backend=${backend//\#\#host_port\#\#/"$port"}
      local backend=${backend//\#\#probe_url\#\#/"$probe_path"}

      local backends="$backends"$'\n'"$backend"$'\n'
    fi
  done <<< "$envs"

  echo "$backends"
}

# $1: backends
create_vcl_init () {
  set -e
  local backends="$1"
  local backends=$(echo "$backends" | sort)

  local vcl_init="sub vcl_init {"
  local last_app=""
  while read -r backend; do
    # we want the "backend [app]_[app_id] {" ones
    if [[ "$backend" == "backend "* && "$backend" == *"{"* ]]; then
      local backend_name=$(echo "$backend" | awk -F' ' '{print $2}')
      # remove app_id from app_app_id, ie. nginx_price_comparator_nl_telecom_portal_doa3wrkprd006
      local app=$(echo "$backend_name" | awk -F'_' '{for(i = 1; i <= NF - 1; i++) printf "%s%s", $i, i == NF -1 ? "" : "_" }')
      # new app
      if [[ "$app" != "$last_app" ]]; then
        local vcl_init="$vcl_init"$'\n'"  new ""$app"" = directors.round_robin();"
        local last_app="$app"
      fi
      local vcl_init="$vcl_init"$'\n'"  $app"".add_backend(""$backend_name"");"
    fi
  done <<< "$backends"

  local vcl_init="$vcl_init"$'\n'"}"
  echo "$vcl_init"
}

# $1: vcl_init
create_vcl_recv () {
  set -e
  local vcl_init="$1"

  local vcl_recv_backend_hints=$(create_vcl_recv_backend_hints "$vcl_init")
  local vcl_recv_unsets=$(create_vcl_recv_unsets)
  local vcl_recv_devicedetect=$(create_vcl_recv_devicedetect)

  local vcl_recv="sub vcl_recv {"
  local vcl_recv="$vcl_recv""$vcl_recv_backend_hints"
  local vcl_recv="$vcl_recv"$'\n'$'\n'"  $vcl_recv_devicedetect"
  local vcl_recv="$vcl_recv"$'\n'"$vcl_recv_unsets"
  local vcl_recv="$vcl_recv"$'\n'$'\n'"  $varnish_vcl_recv_ban"
  local vcl_recv="$vcl_recv"$'\n'$'\n'"  $varnish_vcl_recv_health_check"
  local vcl_recv="$vcl_recv"$'\n'"}"

  echo "$vcl_recv"
}

create_vcl_recv_devicedetect () {
  set -e

  echo "$varnish_vcl_recv_devicedetect"
}

create_vcl_recv_unsets () {
  set -e

  local unset_rules=$'\n'"    unset req.http.Cookie;"
  local unset_rules="$unset_rules"$'\n'"    if (req.http.Authorization) {"
  local unset_rules="$unset_rules"$'\n'"      set req.http.X-Authorization = req.http.Authorization;"
  local unset_rules="$unset_rules"$'\n'"      unset req.http.Authorization;"
  local unset_rules="$unset_rules"$'\n'"    }"
  if [[ -z "$KEEP_CLIENT_COOKIES_AND_AUTH_PATHS" ]]; then
    local vcl_recv_unsets="$unset_rules"
  else
    local first_path=true
    local vcl_recv_unsets=$'\n'"  if ("
    for path in $KEEP_CLIENT_COOKIES_AND_AUTH_PATHS
    do
      if [[ "$first_path" = true ]]; then
        local vcl_recv_unsets="$vcl_recv_unsets""!(req.url ~ \"^""$path""\")"
        local first_path=false
      else
        local vcl_recv_unsets="$vcl_recv_unsets"" && !(req.url ~ \"^""$path""\")"
      fi
    done
    local vcl_recv_unsets="$vcl_recv_unsets"") {""$unset_rules"$'\n'"  }"
  fi

  echo "$vcl_recv_unsets"
}

create_vcl_hash () {
  set -e

  if [[ "$CACHE_AUTHENTICATION_HEADERS" == "1" ]]; then
    local vcl_hash="sub vcl_hash {"
    local vcl_hash="$vcl_hash"$'\n'"  if (req.http.X-Authorization) {"
    local vcl_hash="$vcl_hash"$'\n'"    hash_data(req.http.X-Authorization);"
    local vcl_hash="$vcl_hash"$'\n'"  }"
    local vcl_hash="$vcl_hash"$'\n'"}"
  fi

  echo "$vcl_hash"
}

# $1: vcl_init
create_vcl_recv_backend_hints () {
  set -e
  local vcl_init="$1"
  local vcl_init=$(echo "$vcl_init" | sort)

  while read -r vcl_init_line; do
    # we want the "new [app] = directors.round.robin();" ones
    if [[ "$vcl_init_line" == *"new "* && "$vcl_init_line" == *"directors.round_robin"* ]]; then
      local app=$(echo "$vcl_init_line" | awk -F' ' '{print $2}')
      local app_upper=$(echo "$app" | awk '{print toupper($0)}')
      local backend_hosts_var="$app_upper""_BACKEND_HOSTS"
      eval backend_hosts=\$$backend_hosts_var

      local vcl_recv_backend_hints="$vcl_recv_backend_hints"$'\n'"  if ("
      local first_backend_host=true
      for backend_host in $backend_hosts
      do
        if [[ "$first_backend_host" = true ]]; then
          local vcl_recv_backend_hints="$vcl_recv_backend_hints""req.http.host ~ \"""$backend_host""\""
          local first_backend_host=false
        else
          local vcl_recv_backend_hints="$vcl_recv_backend_hints"" || req.http.host ~ \"""$backend_host""\""
        fi
      done
      local vcl_recv_backend_hints="$vcl_recv_backend_hints"") {"$'\n'"    set req.backend_hint = ""$app"".backend();"$'\n'"  }"$'\n'

    fi
  done <<< "$vcl_init"

  echo "$vcl_recv_backend_hints"
}

create_vcl_synth () {
  set -e
  local vcl_synth="$varnish_vcl_synth"

  echo "$vcl_synth"
}

create_vcl_deliver () {
  set -e

  local vcl_deliver="$varnish_vcl_deliver_base"
  local match_line="req.http.host ~ \"^$\""
  for long_term_client_cache_match in $LONG_TERM_CLIENT_CACHE_MATCHES
  do
    local match_line="$match_line || req.http.host ~ \"$long_term_client_cache_match\""
  done

  local vcl_deliver=${vcl_deliver//\#\#long_term_client_cache_matches\#\#/"$match_line"}

  echo "$vcl_deliver"
}

create_vcl_backend_fetch () {
  set -e

  if [[ "$CACHE_AUTHENTICATION_HEADERS" == "1" ]]; then
    local vcl_backend_fetch="sub vcl_backend_fetch {"
    local vcl_backend_fetch="$vcl_backend_fetch"$'\n'"  if (req.http.X-Authorization) {"
    local vcl_backend_fetch="$vcl_backend_fetch"$'\n'"    set req.http.Authorization = req.http.X-Authorization;"
    local vcl_backend_fetch="$vcl_backend_fetch"$'\n'"  }"
    local vcl_backend_fetch="$vcl_backend_fetch"$'\n'"}"
  fi

  echo "$vcl_backend_fetch"
}

create_vcl_backend_response () {
  set -e

  echo "$varnish_vcl_backend_response"
}

# $1: varnish base
# $2: varnish config file
create_config_file () {
  set -e
  local varnish_base="$1"
  local varnish_vcl_file="$2"

  cat /dev/null > "$varnish_vcl_file"

  # the config file is generated in order Varnish uses the subroutines
  local backends=$(create_backends)
  local vcl_init=$(create_vcl_init "$backends")
  local vcl_recv=$(create_vcl_recv "$vcl_init")
  local vcl_hash=$(create_vcl_hash)
  local vcl_deliver=$(create_vcl_deliver)
  local vcl_synth=$(create_vcl_synth)
  local vcl_backend_fetch=$(create_vcl_backend_fetch)
  local vcl_backend_response=$(create_vcl_backend_response)


  echo "$varnish_base" >> "$varnish_vcl_file"
  echo "$backends"$'\n' >> "$varnish_vcl_file"
  echo "$vcl_init"$'\n' >> "$varnish_vcl_file"
  echo "$vcl_recv"$'\n' >> "$varnish_vcl_file"
  echo "$vcl_hash"$'\n' >> "$varnish_vcl_file"
  echo "$vcl_synth"$'\n' >> "$varnish_vcl_file"
  echo "$vcl_deliver"$'\n' >> "$varnish_vcl_file"
  echo "$vcl_backend_fetch"$'\n' >> "$varnish_vcl_file"
  echo "$vcl_backend_response" >> "$varnish_vcl_file"
}

varnish_vcl_file="/etc/varnish/varnish.vcl"

# remove any existing varnish pid
rm -f /var/run/varnish/*

echo "creating $varnish_vcl_file..."
create_config_file "$varnish_base" "$varnish_vcl_file"

echo "starting varnish..."
exec varnishd -a :6081 -F -u varnish -f "$varnish_vcl_file" -s file,/tmp,"$STORAGE_SIZE"
