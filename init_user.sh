#!/bin/bash
set -e

FIRSTRUN=/firstrun_createuser
if [ -f $FIRSTRUN ]; then
    exit 0
fi
touch $FIRSTRUN

if [ "$CREATE_ADMIN_USER" != "True" ]; then
    exit 0
fi

sleep $1;

jsfile=adduser.js

rm -f $jsfile

cat << EOT >> $jsfile
db.createUser(
    {
        user: '$DB_ADMINUSER', pwd: '$DB_ADMINPASS',
        roles:[
            { role:'root',db:'admin' }
        ]
    }
);
EOT

mongo admin $jsfile
