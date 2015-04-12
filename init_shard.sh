#!/bin/bash
set -e

FIRSTRUN=/firstrun_shard
if [ -f $FIRSTRUN ]; then
    exit 0
fi
touch $FIRSTRUN


if [ "$ROUTER" != "True" ]; then
    exit 0
fi

sleep $1;

# Generate js for sharding
jsfile=sharding.js
rm -f $jsfile

envf=(`env`)
for line in "${envf[@]}"; do
    IFS='='
    set -- $line
    if [[ "$1" =~ ^REPL.*_PORT_27017_TCP$ ]]; then
        rsenv=`echo $1 | grep -o "^REPL[0-9]*"`'_ENV_REPLICA_SET'
        ip=`eval echo '$'$rsenv`'/'`echo $2 | cut -c7-`
        echo "sh.addShard('$ip')" >> $jsfile
    fi
done

echo 'sh.status()' >> $jsfile

if [ "$AUTH" = "True" ]; then
    mongo admin --eval "db.auth('$DB_ADMINUSER', '$DB_ADMINPASS');"
fi
if [ "$AUTH" = "True" ]; then
    mongo admin -u $DB_ADMINUSER -p $DB_ADMINPASS $jsfile
else
    mongo admin $jsfile
fi

./init_user.sh
