#!/bin/sh
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2018, Galen Curwen-McAdams

# A simple Slurp and Sequence System (SAUCY)
#   * starts db, broker, and bridge
#   * currently cannot handle wireless things
#   * use machinic-tangle for wireless things

DB_PORT=7379
DB_HOST="127.0.0.1"

BROKER_PORT=1883
BROKER_HOST="127.0.0.1"

CREATE_PATH="/tmp"
M_TYPE="saucy_simple"

# everything is created in /tmp
# unless a redis-server with same host/port is already running in another directory
( 
    # create a directory to store generated stuff
    cd $CREATE_PATH
    mkdir $CREATE_PATH/$M_TYPE

    # create a config file for redis with keyspace events
    # and saving every 60 seconds if at least 1 key has changed
    printf "notify-keyspace-events KEA\nSAVE 60 1\n" >> redis.conf

    # try to start redis server in background using config file
    # shutdown the server with command:
    # redis-cli -p $DB_PORT shutdown
    redis-server redis.conf --port $DB_PORT &

    # use single quotes for string
    lings-path-add '/slurp -- $(keli neo-slurp _ _ --db-host $DB_HOST --db-port $DB_PORT)' --db-host $DB_HOST --db-port $DB_PORT

    # start broker and bridge
    # use tangle-ui for connecting/discovering wireless things
    mosquitto &

    # start a bridge to handle routing
    # problem: env vars not passed in 
    tangle-bridge --allow-shell-calls --db-host $DB_HOST --db-port $DB_PORT --broker-host $BROKER_HOST --broker-port $BROKER_PORT &

    # create a button
    tangle-things button --model-type kivy --name slurp
    cp -r button_slurp $CREATE_PATH/$M_TYPE
 
    # a little awkward to use button since first user must
    # cd into the button path and then run button with broker parameters 
    # $ cd /tmp/saucy/button_slurp/slurp_button
    # $ python3 button_slurp.py -- --broker-host 127.0.0.1 --broker-port 1883
)
