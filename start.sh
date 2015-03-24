#!/bin/bash
set -e

function replicasetMode() {
    mv -f /etc/sv-rs.conf /etc/supervisord.conf
    sed -i -e "s/REPLICA_SET/$REPLICA_SET/" /etc/supervisord.conf
    
    _out=out.txt
    _iplist=list.txt
    _jsfname=init.js

    IFS=$'\n'
    _envf=(`env`)
    for _line in "${_envf[@]}"; do
        IFS='='
        set -- $_line
        if [[ "$2" =~ ^tcp:// ]]; then
            echo "$2" >> $_out
        fi
    done
    if [ -f $_out ]; then
        IFS=$'\n'
        awk '!x[$0]++' $_out >> $_iplist
        _file=(`cat $_iplist`)
        _IPSELF=`ip -f inet -o addr show eth0|cut -d\  -f 7 | cut -d/ -f 1`
        touch $_jsfname
        echo 'rs.initiate()' >> $_jsfname
        echo "rs.add('$_IPSELF:27017')" >> $_jsfname
        for _line in "${_file[@]}"; do
            _IPSEC=`echo $_line | cut -c7-`
            echo "rs.add('$_IPSEC')" >> $_jsfname
        done
        echo 'rs.status()' >> $_jsfname
        echo 'cfg = rs.conf()' >> $_jsfname
        echo "cfg.members[0].host = '$_IPSELF:27017'" >> $_jsfname
        echo 'rs.reconfig(cfg)' >> $_jsfname
        echo 'rs.status()' >> $_jsfname
    fi
    rm -f $_out $_iplist
}

function configServerMode() {
    mv -f /etc/sv-cs.conf /etc/supervisord.conf
}

function routerMode() {
    mv -f /etc/sv-rt.conf /etc/supervisord.conf

    # Generate CONFIG_SERVER_ADDRS string
    _out=out.txt
    _iplist=list.txt
    _configaddrs=""

    IFS=$'\n'
    _envf=(`env`)
    for _line in "${_envf[@]}"; do
        IFS='='
        set -- $_line
        if [[ "$1" =~ ^CONFIG.*_TCP$ ]]; then
            _ip=`echo $2 | cut -c7-`
            echo $_ip >> $_out
        fi
    done
    if [ -f $_out ]; then
        IFS=$'\n'
        awk '!x[$0]++' $_out >> $_iplist
        _list=(`cat $_iplist`)
        _configaddrs="$(IFS=,; echo "${_list[*]}")"
    fi
    rm -f $_out $_iplist

    sed -i -e "s/CONFIG_SERVER_ADDRS/$_configaddrs/" /etc/supervisord.conf

    # Generate sharding.js
    _jsfname=init.js
    touch $_jsfname
    IFS=$'\n'
    _envf=(`env`)
    for _line in "${_envf[@]}"; do
        IFS='='
        set -- $_line
        if [[ "$1" =~ ^REPL.*_TCP$ ]]; then
            _rsenv=`echo $1 | grep -o "^REPL[0-9]*"`'_ENV_REPLICA_SET'
            _ip=`eval echo '$'$_rsenv`'/'`echo $2 | cut -c7-`
            echo "sh.addShard('$_ip')" >> $_jsfname
        fi
    done
    echo 'sh.status()' >> $_jsfname
}

REPLICA_SET=${REPLICA_SET:-""}
CONFIG_SERVER=${CONFIG_SERVER:-"False"}
ROUTER=${ROUTER:-"False"}

if [ "${1:0:1}" = '-' ]; then
    set -- mongod "$@"
fi

numa='numactl --interleave=all'
if $numa true &> /dev/null; then
    set -- $numa "$@"
fi

chown -R mongodb:mongodb /data/db

if [ "$REPLICA_SET" != "" ]; then
    replicasetMode
elif [ "$CONFIG_SERVER" = "True" ]; then
    configServerMode
elif [ "$ROUTER" = "True" ]; then
    routerMode
else
    mv -f /etc/sv.conf /etc/supervisord.conf
fi

# Executing supervisord
supervisord -n