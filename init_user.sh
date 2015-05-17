#!/bin/bash
set -e

FIRSTRUN=/firstrun_createuser
if [ -f $FIRSTRUN ]; then
    exit 0
fi
touch $FIRSTRUN

if [ "$CREATE_ADMINUSER" != "true" ]; then
    exit 0
fi

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
