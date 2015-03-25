#!/bin/bash
set -e

if [ "$CREATE_ADMIN_USER" != "True" ]; then
    exit 0
fi

sleep $1;

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
rm -f adduser.js