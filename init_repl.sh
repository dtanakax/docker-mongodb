#!/bin/bash
set -e

if [ "$REPLICA_SET" = "" ]; then
    exit 0
fi

sleep $1;

# Generate js for replicaset
out=out.txt
iplist=list.txt
jsfname=init.js

IFS=$'\n'
envf=(`env`)
for line in "${envf[@]}"; do
    IFS='='
    set -- $line
    if [[ "$2" =~ ^tcp:// ]]; then
        echo "$2" >> $out
    fi
done

if [ -f $out ]; then
    IFS=$'\n'
    awk '!x[$0]++' $out >> $iplist
    file=(`cat $iplist`)
    IPSELF=`ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1`

    touch $jsfname
    echo 'rs.initiate()' >> $jsfname
    echo "rs.add('$IPSELF:27017')" >> $jsfname
    for line in "${file[@]}"; do
        IPSEC=`echo $line | cut -c7-`
        echo "rs.add('$IPSEC')" >> $jsfname
    done
    echo 'rs.status()' >> $jsfname
    echo 'cfg = rs.conf()' >> $jsfname
    echo "cfg.members[0].host = '$IPSELF:27017'" >> $jsfname
    echo 'rs.reconfig(cfg)' >> $jsfname
    echo 'rs.status()' >> $jsfname
fi
rm -f $out $iplist

if [ -f $jsfname ]; then
    mongo admin -u $DB_ADMINUSER -p $DB_ADMINPASS $jsfname
fi