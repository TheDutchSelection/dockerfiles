#! /bin/bash
set -e

data_directory=$1
recovery_target=$2
recovery_data_directory="/tmp"

/usr/bin/psql -c "select pg_start_backup('pgpool-recovery')" postgres
echo "restore_command = '/usr/bin/ssh -T ""$HOST_IP"" \'mkdir -p /tmp/archive_log;docker run --volumes-from postgresql_master_data --rm -v /tmp/archive_log:/tmp/archive_log --entrypoint=\"cp ""$data_directory""archive_log/*" "/tmp/archive_log/\" thedutchselection/data:latest\';/usr/bin/scp ""$HOST_IP"":""$data_directory""archive_log/%f %p" > "$data_directory""recovery.conf"
/bin/tar -C "$data_directory" -zcf pgsql.tar.gz "$data_directory"
/usr/bin/psql -c 'select pg_stop_backup()' postgres
/usr/bin/scp pgsql.tar.gz $recovery_target:$recovery_data_directory