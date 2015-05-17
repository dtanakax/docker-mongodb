#!/bin/bash
set -e

if [ "$1" = "supervisord" ]; then
    # Mongo options
    if [ "$OPTIONS" = "**None**" ]; then
        unset OPTIONS
    fi
    if [ "$REPLICA_SET" = "**None**" ]; then
        unset REPLICA_SET
    fi

    OPTION_AUTH=""
    if [ "$AUTH" = "true" ]; then
        OPTION_AUTH="--keyFile \/etc\/certs\/mongodb.keyfile"
    fi
    OPTION_COMMON="--port 27017 --noprealloc --smallfiles"

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
        if [ "$CREATE_ADMINUSER" = "true" ]; then
            createAdminUser
        fi

        cp -f /etc/sv-rs.conf /etc/supervisord.conf
        local options="--replSet $REPLICA_SET $OPTION_COMMON $OPTION_AUTH $OPTIONS"
        sed -i -e "s/__MONGO_OPTIONS/$options/
                   s/__REPLICATION_DELAY/$REPLICATION_DELAY/" /etc/supervisord.conf
    }

    function configServerMode() {
        cp -f /etc/sv-cs.conf /etc/supervisord.conf
        options="--configsvr --dbpath \/data\/configdb $OPTION_COMMON $OPTION_AUTH $OPTIONS"
        sed -i -e "s/__MONGO_OPTIONS/$options/" /etc/supervisord.conf
    }

    function routerMode() {
        # Generate CONFIG_SERVER_ADDRS string
        local _configaddrs=""
        local _configs=()

        if [[ `env | grep ^CONFIG.*_PORT_27017_TCP_ADDR` ]]; then
            _configaddrs="$(env | grep ^CONFIG.*_PORT_27017_TCP_ADDR | sed 's/^CONFIG.*_PORT_27017_TCP_ADDR=//g')"
        fi

        if [ "$_configaddrs" = "" ]; then
            return 0
        fi

        IFS=$'\n'
        _configaddrs=(`echo "$_configaddrs" | awk '!x[$0]++'`)

        for iprs in "${_configaddrs[@]}"; do
            _configs+=("$iprs:27017")
        done

        _configs="$(IFS=,; echo "${_configs[*]}")"

        cp -f /etc/sv-rt.conf /etc/supervisord.conf
        local options="--configdb $_configs --port 27017 $OPTION_AUTH $OPTIONS"
        sed -i -e "s/__MONGO_OPTIONS/$options/
                   s/__SHARDING_DELAY/$SHARDING_DELAY/" /etc/supervisord.conf
    }

    function singleMode() {
        if [ "$CREATE_ADMINUSER" = "true" ]; then
            createAdminUser
        fi

        cp -f /etc/sv.conf /etc/supervisord.conf
        local options="$OPTION_COMMON $OPTION_AUTH $OPTIONS"
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

        if [ -n "$REPLICA_SET" ]; then
            replicasetMode
        elif [ "$CONFIG_SERVER" = "true" ]; then
            configServerMode
        elif [ "$ROUTER" = "true" ]; then
            routerMode
        else
            singleMode
        fi
        touch $FIRSTRUN
    else
        if [ "$ROUTER" = "true" ]; then
            routerMode
        fi
    fi
fi

exec "$@"