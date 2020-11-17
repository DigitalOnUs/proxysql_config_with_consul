#!/bin/bash
set -e

sleep 10

token_file="/consul/token"

export CONSUL_HTTP_TOKEN="$(cat $token_file)"

echo "*** Starting consul-agent ***"

if [ -z "${CONSUL_HTTP_TOKEN}" ]; then

    exec consul agent -data-dir=/consul/data -config-dir=/consul/config -client=0.0.0.0 -datacenter "${CONSUL_DATACENTER}" -node "ProxySQL-${HOSTNAME}" -retry-join "consul" -enable-local-script-checks

else

    echo '{}' > dummy.json && jq ".acl.enabled=true|.acl.tokens.default=\"${CONSUL_HTTP_TOKEN}\"" dummy.json | tee /consul/config/default.json

    exec consul agent -data-dir=/tmp/consul -config-dir=/consul/config -client=0.0.0.0 -datacenter "${CONSUL_DATACENTER}" -node "ProxySQL-${HOSTNAME}" -retry-join "consul"

fi
