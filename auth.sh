#!/bin/bash
set -e

sleep $1;
if [ "$CREATE_ADMIN_USER" = "True" ]; then
    mongo admin --eval "db.auth('$DB_ADMINUSER', '$DB_ADMINPASS');"
fi