#!/bin/sh
set -e

if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi
rails db:migrate db:seed assets:precompile

exec bundle exec "$@"
