#! /bin/bash
set -e

data_directory=$1
recovery_target=$2

echo "pg_start_backup..."
/usr/bin/psql -c "select pg_start_backup('pgpool-recovery')" postgres
echo "restore_command = 'wal-e wal-fetch %f %p'" > "$data_directory""recovery.conf"
if [[ -z "$AWS_S3_WALE_BUCKET_BASE_PATH" || "$AWS_S3_WALE_BUCKET_BASE_PATH" =="/" ]]; then
  wal-e --s3-prefix="s3://""$AWS_S3_WALE_BUCKET_NAME""/""$HOST_IP" backup-push "$data_directory"
else
  wal-e --s3-prefix="s3://""$AWS_S3_WALE_BUCKET_NAME""/""$AWS_S3_WALE_BUCKET_BASE_PATH""$HOST_IP" backup-push "$data_directory"
fi
/usr/bin/psql -c 'select pg_stop_backup()' postgres
rm "$data_directory""recovery.conf"