#!/bin/sh
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2018, Galen Curwen-McAdams

DB_PORT=7379
DB_HOST="127.0.0.1"

# this script creates a ~90 page boook and puts into a redis database
# everything is created in /tmp
# unless a redis-server with same host/port is already running in another directory
cd /tmp/

# create a config file for redis with keyspace events
# and saving every 60 seconds if at least 1 key has changed
printf "notify-keyspace-events KEA\nSAVE 60 1\n" >> redis.conf

# try to start redis server in background using config file
# shutdown the server with command:
# redis-cli -p $DB_PORT shutdown
redis-server redis.conf --port $DB_PORT &

# generate a boook with 3 sections of 30 pages each plus covers and title page, and toc
primitives-generate-boook --title boook --section foo 30 full --section bar 30 full --section baz 30 full --manifest csv --verbose

# use the generated csv file to ingest generated images
# clears existing items in database
fold-ui-fairytale --ingest-manifest boook.csv --ingest-map filename binary_key --ingest-as-binary filename --db-del-pattern "glworb:*" --db-port 7379 --verbose

# there should be things in the database
echo "script finished, you may want to start fold-ui by running"
echo "fold-ui --size=1500x800 -- --db-port $DB_PORT --db-host $DB_HOST"
echo "to stop redis-server:"
echo "redis-cli -p $DB_PORT shutdown"