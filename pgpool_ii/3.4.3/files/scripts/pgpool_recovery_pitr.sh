#! /bin/bash
set -e

data_directory=$1
recovery_target=$2
recovery_data_directory=$3
archive_directory="$data_directory""archive_status"

# Force to flush current value of sequences to xlog
/usr/bin/psql -t -c 'SELECT datname FROM pg_database WHERE NOT datistemplate AND datallowconn' template1|
while read i
do
  if [ "$i" != "" ];then
    /usr/bin/psql -c "SELECT setval(oid, nextval(oid)) FROM pg_class WHERE relkind = 'S'" $i
  fi
done

/usr/bin/psql -c "SELECT pgpool_switch_xlog($archive_directory)" template1