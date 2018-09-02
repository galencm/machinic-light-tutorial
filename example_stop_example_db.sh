#!/bin/sh
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2018, Galen Curwen-McAdams

# a simple script to stop the redis server started
# in examples

DB_PORT=7379
DB_HOST="127.0.0.1"

redis-cli -p $DB_PORT shutdown