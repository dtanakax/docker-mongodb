# Set the base image
FROM debian:wheezy

# File Author / Maintainer
MAINTAINER Daisuke Tanaka, tanaka@infocorpus.com

ENV DEBIAN_FRONTEND noninteractive

# MongoDB version
ENV MONGO_MAJOR 3.0
ENV MONGO_VERSION 3.0.1

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mongodb && useradd -r -g mongodb mongodb

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl \
        numactl \
        supervisor \
        pwgen \
    && rm -rf /var/lib/apt/lists/*

RUN apt-key adv --keyserver pool.sks-keyservers.net --recv-keys 492EAFE8CD016A07919F1D2B9ECBEC467F0CEB10

RUN echo "deb http://repo.mongodb.org/apt/debian wheezy/mongodb-org/$MONGO_MAJOR main" > /etc/apt/sources.list.d/mongodb-org.list

RUN set -x \
    && apt-get update \
    && apt-get install -y mongodb-org=$MONGO_VERSION \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mongodb \
    && mv /etc/mongod.conf /etc/mongod.conf.orig

RUN apt-get clean all

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/mongodb/mongod.log

RUN mkdir -p /data/db && chown -R mongodb:mongodb /data/db

COPY start.sh /start.sh
COPY init_repl.sh /init_repl.sh
COPY init_shard.sh /init_shard.sh
COPY init_user.sh /init_user.sh
COPY auth.sh /auth.sh
COPY sv.conf /etc/sv.conf
COPY sv-rs.conf /etc/sv-rs.conf
COPY sv-rt.conf /etc/sv-rt.conf
COPY sv-cs.conf /etc/sv-cs.conf
COPY mongodb-keyfile /etc/mongodb-keyfile

RUN chmod +x /start.sh \
    && chmod +x /init_repl.sh \
    && chmod +x /init_shard.sh \
    && chmod +x /init_user.sh \
    && chmod +x /auth.sh \
    && chmod 600 /etc/mongodb-keyfile

VOLUME ["/data/db"]

EXPOSE 27017

CMD ["/bin/bash", "/start.sh"]