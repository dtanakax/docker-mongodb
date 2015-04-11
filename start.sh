#!/bin/bash
set -e

# Mongo options
OPTION_AUTH=""
if [ "$AUTH" = "True" ]; then
    OPTION_AUTH="--keyFile \/etc\/mongodb-keyfile"
fi
OPTION_COMMON="--noprealloc --smallfiles"
if [ "$JOURNAL" = "False" ]; then
    OPTION_COMMON="${OPTION_COMMON} --nojournal"
fi

function createAdminUser() {
    mongod --smallfiles --nojournal &

    RET=1
    while [[ RET -ne 0 ]]; do
        echo "=> Waiting for confirmation of MongoDB service startup"
        sleep 5
        mongo admin --eval "help" >/dev/null 2>&1
        RET=$?
    done

    echo "=> Creating an $DB_ADMINUSER user with a $DB_ADMINPASS password in MongoDB"
    mongo admin --eval "db.createUser({user: '$DB_ADMINUSER', pwd: '$DB_ADMINPASS', roles:[{role:'root',db:'admin'}]});"
    mongo admin --eval "db.shutdownServer();"
    echo "=> Done!"
}

function replicasetMode() {
    if [ "$CREATE_ADMINUSER" = "True" ]; then
        createAdminUser
    fi

    cp -f /etc/sv-rs.conf /etc/supervisord.conf
    local options="--replSet $REPLICA_SET $OPTION_COMMON $OPTION_AUTH"
    sed -i -e "s/__MONGO_OPTIONS/$options/
               s/__REPLICATION_DELAY/$REPLICATION_DELAY/" /etc/supervisord.conf
}

function configServerMode() {
    cp -f /etc/sv-cs.conf /etc/supervisord.conf
    options="--configsvr --dbpath \/data\/configdb --port 27017 $OPTION_COMMON $OPTION_AUTH"
    sed -i -e "s/__MONGO_OPTIONS/$options/" /etc/supervisord.conf
}

function routerMode() {
    # Generate CONFIG_SERVER_ADDRS string
    local _out=out.txt
    local _iplist=list.txt
    local _configaddrs=""

    IFS=$'\n'
    local _envf=(`env`)
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

    cp -f /etc/sv-rt.conf /etc/supervisord.conf
    local options="--configdb $_configaddrs --port 27017 $OPTION_AUTH"
    sed -i -e "s/__MONGO_OPTIONS/$options/
               s/__SHARDING_DELAY/$SHARDING_DELAY/" /etc/supervisord.conf
}

function singleMode() {
    if [ "$CREATE_ADMINUSER" = "True" ]; then
        createAdminUser
    fi

    cp -f /etc/sv.conf /etc/supervisord.conf
    local options="$OPTION_COMMON $OPTION_AUTH"
    sed -i -e "s/__MONGO_OPTIONS/$options/" /etc/supervisord.conf
}

if [ "${1:0:1}" = '-' ]; then
    set -- mongod "$@"
fi

numa='numactl --interleave=all'
if $numa true &> /dev/null; then
    set -- $numa "$@"
fi

FIRSTRUN=/firstrun_mongo
if [ ! -f $FIRSTRUN ]; then
    chown -R mongodb:mongodb /data/db

    if [ "$REPLICA_SET" != "" ]; then
        replicasetMode
    elif [ "$CONFIG_SERVER" = "True" ]; then
        configServerMode
    elif [ "$ROUTER" = "True" ]; then
        routerMode
    else
        singleMode
    fi
    touch $FIRSTRUN
else
    if [ "$ROUTER" = "True" ]; then
        routerMode
    fi
fi

# Executing supervisord
supervisord -n