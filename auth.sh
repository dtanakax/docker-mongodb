#!/bin/bash
set -e

RUNONCE=/runonce_auth
if [ -f $RUNONCE ]; then
    exit 0
fi
touch $RUNONCE

sleep $1;
if [ "$CREATE_ADMIN_USER" = "True" ]; then
    mongo admin --eval "db.auth('$DB_ADMINUSER', '$DB_ADMINPASS');"
fi