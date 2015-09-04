#! /bin/bash
set -e

data_directory=$1
recovery_target=$2
recovery_data_directory=$3
archive_dummy_directory="$DATA_DIRECTORY""pg_xlog/dummy_archive"

# Force to flush current value of sequences to xlog
/usr/bin/psql -t -c 'SELECT datname FROM pg_database WHERE NOT datistemplate AND datallowconn' template1|
while read i
do
  if [ "$i" != "" ];then
    /usr/bin/psql -c "SELECT setval(oid, nextval(oid)) FROM pg_class WHERE relkind = 'S'" $i
  fi
done

#/usr/bin/psql -c "SELECT pgpool_switch_xlog('""$archive_dummy_directory""')" template1
#
# pgpool_switch_xlog is not working with wale, not sure what the problem is, the only thing pgpool_switch_xlog does
# different from pg_switch_xlog is checking if the file exists, so we do that manually and have the same functionallity.
/usr/bin/psql -c "SELECT pg_switch_xlog()" template1

echo "waiting for $archive_dummy_directory to become not empty..."
end_loop="false"
while [[ ! "$end_loop" == "true" ]]; do
  if [[ -d "$archive_dummy_directory" && "$(ls -A $archive_dummy_directory)" ]]; then
    echo "switch xlog done!"
    end_loop="true"
  else
    sleep 1
  fi
done
