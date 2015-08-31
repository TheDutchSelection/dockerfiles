#! /bin/bash
set -e

create_wale_prefix () {
  set -e

  if [[ -z "$AWS_S3_WALE_BUCKET_BASE_PATH" || "$AWS_S3_WALE_BUCKET_BASE_PATH" == "/" ]]; then
    local wale_s3_prefix="s3://""$AWS_S3_WALE_BUCKET_NAME""/""$HOST_IP"
  else
    local wale_s3_prefix"s3://""$AWS_S3_WALE_BUCKET_NAME""/""$AWS_S3_WALE_BUCKET_BASE_PATH""$HOST_IP"
  fi

  echo "$wale_s3_prefix"
}

wale_s3_prefix=$(create_wale_prefix)
wal-e --s3-prefix="$wale_s3_prefix" backup-push "$DATA_DIRECTORY"
