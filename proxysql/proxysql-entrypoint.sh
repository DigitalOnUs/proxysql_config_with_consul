#!/bin/bash
set -e

sleep 20

## ProxySQL entrypoint
## ===================
##
## Supported environment variables:
##
## MONITOR_CONFIG_CHANGE={true|false}
## - Monitor /etc/proxysql.cnf for any changes and reload ProxySQL automatically
##

# If command has arguments, prepend proxysql
if [ "${1:0:1}" == '-' ]; then
    CMDARG="$@"
fi

CONFIG="/proxysql/${CONFIG:-config.sql}"
CONFIG_CTPL="/proxysql/${CONFIG_CTPL:-config.sql.ctpl}"

touch $CONFIG

echo "*** Starting ProxySQL ***"

if [[ $MONITOR_CONFIG_CHANGE ]]
then

    # Start ProxySQL in the background

    proxysql -f -c /etc/proxysql.cnf $CMDARG &

    consul-template -template ${CONFIG_CTPL}:${CONFIG} &

    oldcksum=$(cksum ${CONFIG})

    echo "Monitoring $CONFIG for changes.."
    while sleep 3
    do
        # Look for any ProxySQL configuration change (the file is updated through consul-templates process)
        newcksum=$(cksum ${CONFIG})
        if [ "${newcksum}" != "${oldcksum}" ]; then
            echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++"
            echo "At $(date) ${CONFIG} update detected."
            echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++"
            oldcksum=$newcksum
            echo "Reloading Configuration ProxySQL.."
            mysql -uadmin -padmin -h127.0.0.1 -P6032 < ${CONFIG}
        fi
    done

else 
    # Start ProxySQL with PID 1
    exec proxysql -f -c /etc/proxysql.cnf $CMDARG
fi

