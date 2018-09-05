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
