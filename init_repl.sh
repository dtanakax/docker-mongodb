#!/bin/bash
set -e

# Files that are created in the first run
FIRSTRUN=/firstrun_repl

if [ "$REPLICA_SET" = "" ]; then
    exit 0
fi

sleep $1;

# Generate js for replicaset
out=out.txt
iplist=list.txt
jsfname=init.js

rm -f $jsfname

IFS=$'\n'
envf=(`env`)
for line in "${envf[@]}"; do
    IFS='='
    set -- $line
    if [[ "$2" =~ ^tcp:// ]]; then
        echo "$2" >> $out
    fi
done

if [ ! -f $out ]; then
    exit 0
fi

IFS=$'\n'
awk '!x[$0]++' $out >> $iplist
file=(`cat $iplist`)
IPSELF=`ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1`

touch $jsfname

if [ ! -f $FIRSTRUN ]; then
    echo 'rs.initiate()' >> $jsfname
    echo "rs.add('$IPSELF:27017')" >> $jsfname
    for line in "${file[@]}"; do
        IPSEC=`echo $line | cut -c7-`
        echo "rs.add('$IPSEC')" >> $jsfname
    done

    echo 'cfg = rs.conf()' >> $jsfname
    echo "cfg.members[0].host = '$IPSELF:27017'" >> $jsfname

    # This instance is the primary only
    echo 'cfg.members[0].priority = 100' >> $jsfname
    echo 'rs.reconfig(cfg)' >> $jsfname

    # Create first run file
    touch $FIRSTRUN
else
    echo 'cfg = rs.conf()' >> $jsfname
    echo "cfg.members[0].host = '$IPSELF:27017'" >> $jsfname

    # This instance is the primary only
    echo 'cfg.members[0].priority = 100' >> $jsfname
    idx=1
    for line in "${file[@]}"; do
        IPSEC=`echo $line | cut -c7-`
        echo "cfg.members[$idx].host = '$IPSEC'" >> $jsfname
        idx=$((idx+1))
    done
    echo 'rs.reconfig(cfg, { force: true })' >> $jsfname
fi
rm -f $out $iplist

# Exec replication script
mongo admin -u $DB_ADMINUSER -p $DB_ADMINPASS $jsfname
