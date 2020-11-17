FROM debian:stretch

####################################################
####   Installing ProxySQL
####################################################

ENV VERSION 2.0.13

RUN apt-get update && \
    apt-get install -y wget mysql-client inotify-tools procps curl unzip vim supervisor jq && \
    wget --no-check-certificate https://github.com/sysown/proxysql/releases/download/v${VERSION}/proxysql_${VERSION}-debian9_amd64.deb -O /opt/proxysql_${VERSION}-debian9_amd64.deb && \
    dpkg -i /opt/proxysql_${VERSION}-debian9_amd64.deb && \
    rm -f /opt/proxysql_${VERSION}-debian9_amd64.deb && \
    rm -rf /var/lib/apt/lists/*

####################################################
####   Installing consul-template
####################################################

RUN cd /usr/local/bin/ && \
    wget https://releases.hashicorp.com/consul-template/0.24.1/consul-template_0.24.1_linux_amd64.zip --no-check-certificate && \
    unzip consul-template_0.24.1_linux_amd64.zip && \
    rm -f consul-template_0.24.1_linux_amd64.zip

####################################################
####   Installing consul-agent
####################################################

ENV VER="1.8.5"

RUN cd /tmp && wget https://releases.hashicorp.com/consul/${VER}/consul_${VER}_linux_amd64.zip --no-check-certificate && \
    unzip consul_${VER}_linux_amd64.zip && \
    mv consul /usr/local/bin

VOLUME /var/lib/proxysql
EXPOSE 10000 12000 6032 6033 6080 8300/tcp 8301/tcp 8301/udp 8302/tcp 8302/udp 8500/tcp 8501/tcp 8502/tcp 8600/tcp 8600/udp

RUN mkdir -p /consul/data /consul/config
COPY proxysql_healthcheck.json /consul/config/proxysql_healthcheck.json

RUN mkdir -p /proxysql/logs
COPY config.sql.ctpl /proxysql/config.sql.ctpl

COPY proxysql.cnf ./etc/proxysql.cnf

ADD consul-entrypoint.sh /consul-entrypoint.sh
RUN chmod 755 /consul-entrypoint.sh

ADD proxysql-entrypoint.sh /proxysql-entrypoint.sh
RUN chmod 755 /proxysql-entrypoint.sh

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENTRYPOINT ["/usr/bin/supervisord"]
