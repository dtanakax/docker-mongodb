#!/bin/bash
set -e

FIRSTRUN=/runonce_createuser
if [ -f $FIRSTRUN ]; then
    exit 0
fi
touch $FIRSTRUN

if [ "$CREATE_ADMIN_USER" != "True" ]; then
    exit 0
fi

sleep $1;

rm -f adduser.js

cat << EOT >> adduser.js
db.createUser(
    {
        user: '$DB_ADMINUSER', pwd: '$DB_ADMINPASS',
        roles:[
            { role:'root',db:'admin' }
        ]
    }
);
EOT

mongo admin adduser.js
