# Set the base image
FROM tanaka0323/debianjp:wheezy

# File Author / Maintainer
MAINTAINER Daisuke Tanaka, tanaka@infocorpus.com

ENV DEBIAN_FRONTEND noninteractive

# MongoDB version
ENV MONGO_MAJOR 3.0
ENV MONGO_VERSION 3.0.2

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mongodb && useradd -r -g mongodb mongodb

RUN apt-get -y update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl \
        numactl \
        supervisor \
    && rm -rf /var/lib/apt/lists/*

RUN apt-key adv --keyserver pool.sks-keyservers.net --recv-keys 492EAFE8CD016A07919F1D2B9ECBEC467F0CEB10

RUN echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/$MONGO_MAJOR main" > /etc/apt/sources.list.d/mongodb-org.list

RUN set -x \
    && apt-get -y update \
    && apt-get install -y mongodb-org=$MONGO_VERSION \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mongodb \
    && mv /etc/mongod.conf /etc/mongod.conf.orig

RUN apt-get clean all

# Environment variables
ENV DB_ADMINUSER    admin
ENV DB_ADMINPASS    password
#ENV REPLICA_SET
ENV CONFIG_SERVER       False
ENV ROUTER              False
ENV CREATE_ADMINUSER    False
ENV AUTH                False
ENV JOURNAL             True
ENV REPLICATION_DELAY   20
ENV SHARDING_DELAY      40
ENV HTTP_INTERFACE      False
ENV REST_API            False

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/mongodb/mongod.log

RUN mkdir -p /data/db && mkdir -p /etc/certs/ && \
    chown -R mongodb:mongodb /data/db

RUN openssl rand -base64 741 > /etc/certs/mongodb.keyfile

COPY start.sh /start.sh
COPY init_repl.sh /init_repl.sh
COPY init_shard.sh /init_shard.sh
COPY init_user.sh /init_user.sh
COPY sv.conf /etc/sv.conf
COPY sv-rs.conf /etc/sv-rs.conf
COPY sv-rt.conf /etc/sv-rt.conf
COPY sv-cs.conf /etc/sv-cs.conf

RUN chmod +x /start.sh \
    && chmod +x /init_repl.sh \
    && chmod +x /init_shard.sh \
    && chmod +x /init_user.sh \
    && chown -R mongodb:mongodb /etc/certs \
    && chmod 600 /etc/certs/mongodb.keyfile

VOLUME ["/data/db", "/etc/certs"]

ENTRYPOINT ["./start.sh"]

EXPOSE 27017

CMD ["supervisord", "-n"]