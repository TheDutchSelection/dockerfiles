#!/bin/bash
#
# REQUIRED ENVS:
# APP_ENV (ie. production)
# APP_ID (ie. price_comparator)
# CAPTAIN_HOST_PUBLIC_IP (ie. 10.0.0.1)
# CAPTAIN_HOST_PORT (ie. 1001)
# DOCKER_IMAGE_NAME (ie. price_comparator)
# DOCKER_IMAGE_TAG (ie. latest)
#
# OPTIONAL ENVS:
# PROBE_PATH (ie. "/sim-only")

set -e

if [[ -z "$APP_ID" || -z "$APP_ENV" || -z "$DOCKER_IMAGE_NAME" || -z "$DOCKER_IMAGE_TAG" ]]; then
  echo "APP_ID, APP_ENV, DOCKER_IMAGE_NAME of DOCKER_IMAGE_TAG variables not set..."
  exit 1
fi

result=$(curl \'http://"$CAPTAIN_HOST_PUBLIC_IP":"$CAPTAIN_HOST_PORT"/update/?env="$APP_ENV"&app="$APP_ID"&docker_image_name="$DOCKER_IMAGE_NAME"&docker_image_tag="$DOCKER_IMAGE_TAG"&probe_path="$PROBE_PATH"\')

if [[ "$result" == *"\"status\": \"200\""* ]]; then
  echo "$APP_ID deployed in $APP_ENV"
  echo "$result"
else
  echo "$APP_ID deploy in $APP_ENV failed"
  echo "$result"
  exit 1
fi