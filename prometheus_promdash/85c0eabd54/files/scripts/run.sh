#!/bin/bash
set -e

echo "precompiling..."
bundle exec rake assets:precompile

echo "migrating database..."
bundle exec rake db:create db:migrate

echo "starting application as webserver..."
exec bundle exec rails s
