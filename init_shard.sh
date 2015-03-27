#!/bin/bash
set -e

FIRSTRUN=/runonce_shard
if [ -f $FIRSTRUN ]; then
    exit 0
fi
touch $FIRSTRUN

if [ "$ROUTER" != "True" ]; then
    exit 0
fi

sleep $1;

# Generate js for sharding
flg=false
jsfile=sharding.js
rm -f $jsfile

touch $jsfile
IFS=$'\n'
envf=(`env`)
for line in "${envf[@]}"; do
    IFS='='
    set -- $line
    if [[ "$1" =~ ^REPL.*_TCP$ ]]; then
        rsenv=`echo $1 | grep -o "^REPL[0-9]*"`'_ENV_REPLICA_SET'
        ip=`eval echo '$'$rsenv`'/'`echo $2 | cut -c7-`
        echo "sh.addShard('$ip')" >> $jsfile
        flg=true
    fi
done
echo 'sh.status()' >> $jsfile

if [ $flg = true ]; then
    mongo admin -u $DB_ADMINUSER -p $DB_ADMINPASS $jsfile
fi
