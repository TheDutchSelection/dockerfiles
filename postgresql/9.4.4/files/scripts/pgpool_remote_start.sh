#! /bin/bash
set -e

recovery_target=$1
recovery_data_directory=$2

ssh -T $recovery_target 'docker run --volumes-from postgresql_master_data -v /tmp:/backup --entrypoint="tar zxf /tmp/pgsql.tar.gz" thedutchselection/data:latest'
ssh -T $recovery_target 'sudo systemctl enable /etc/tds/units/postgresql_master/app/postgresql_master.service;sudo systemctl enable /etc/tds/units/postgresql_master/sidekick/postgresql_master_restarter.service'