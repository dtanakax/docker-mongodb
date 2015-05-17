#!/bin/bash
set -e

# Files that are created in the first run
FIRSTRUN=/firstrun_repl
_DBPORT=27017

if [ "$REPLICA_SET" = "" ]; then
    exit 0
fi

sleep $1;

# Generate js for replicaset
jsfname=init.js
rm -f $jsfname

replicaset=""
if [[ `env | grep ^DB.*_PORT_27017_TCP_ADDR` ]]; then
    replicaset="$(env | grep ^DB.*_PORT_27017_TCP_ADDR | sed 's/^DB.*_PORT_27017_TCP_ADDR=//g')"
fi

if [ "$replicaset" = "" ]; then
    exit 0
fi

touch $jsfname

IFS=$'\n'
replicaset=(`echo "$replicaset" | awk '!x[$0]++'`)

iplocal=`ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1`

if [ ! -f $FIRSTRUN ]; then
    echo 'rs.initiate()' >> $jsfname
    echo "rs.add('$iplocal:$_DBPORT')" >> $jsfname
    for iprs in ${replicaset[@]}; do
        echo "rs.add('$iprs:$_DBPORT')" >> $jsfname
    done

    echo 'cfg = rs.conf()' >> $jsfname
    echo "cfg.members[0].host = '$iplocal:$_DBPORT'" >> $jsfname

    # This instance is the primary only
    echo 'cfg.members[0].priority = 100' >> $jsfname
    echo 'rs.reconfig(cfg)' >> $jsfname

    # Create first run file
    touch $FIRSTRUN
else
    echo 'cfg = rs.conf()' >> $jsfname
    echo "cfg.members[0].host = '$iplocal:$_DBPORT'" >> $jsfname

    # This instance is the primary only
    echo 'cfg.members[0].priority = 100' >> $jsfname
    idx=1
    for iprs in ${replicaset[@]}; do
        echo "cfg.members[$idx].host = '$iprs:$_DBPORT'" >> $jsfname
        idx=$((idx+1))
    done
    echo 'rs.reconfig(cfg, { force: true })' >> $jsfname
fi

if [ "$AUTH" = "true" ]; then
    mongo admin --eval "db.auth('$DB_ADMINUSER', '$DB_ADMINPASS');"
fi
if [ "$AUTH" = "true" ]; then
    mongo admin -u $DB_ADMINUSER -p $DB_ADMINPASS $jsfname
else
    mongo admin $jsfname
fi
