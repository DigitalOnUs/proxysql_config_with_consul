#!/bin/bash
set -e

sleep 20

function update_credentials {
    echo -e "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\nAt $(date) MYSQL Password update detected.\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    update_global_variables ${1} ${2}
    update_mysql_users ${1} ${2}
}

function update_global_variables {
    mysql -uadmin -padmin -h127.0.0.1 -P6032 -e "UPDATE global_variables SET variable_value='${1}' WHERE variable_name='mysql-monitor_username';"
    mysql -uadmin -padmin -h127.0.0.1 -P6032 -e "UPDATE global_variables SET variable_value='${2}' WHERE variable_name='mysql-monitor_password';"
    mysql -uadmin -padmin -h127.0.0.1 -P6032 -e "LOAD MYSQL VARIABLES TO RUNTIME;"
    mysql -uadmin -padmin -h127.0.0.1 -P6032 -e "SAVE MYSQL VARIABLES TO DISK;"
}

function update_mysql_users {
    TMP_USER=${1}
    SQL="SELECT password FROM mysql_users where username='${TMP_USER}';"
    COUNT=$(mysql -uadmin -padmin -h127.0.0.1 -P6032 -NBe "${SQL}" | wc -l)

    if [ $COUNT -gt 0 ]; then
        mysql -uadmin -padmin -h127.0.0.1 -P6032 -e "UPDATE mysql_users set password='${2}' WHERE username='${1}';"
    else 
        mysql -uadmin -padmin -h127.0.0.1 -P6032 -e "INSERT INTO mysql_users (username,password) VALUES ('${1}','${2}');"
    fi
    mysql -uadmin -padmin -h127.0.0.1 -P6032 -e "LOAD MYSQL USERS TO RUNTIME;"
    mysql -uadmin -padmin -h127.0.0.1 -P6032 -e "SAVE MYSQL USERS TO MEMORY;"
    mysql -uadmin -padmin -h127.0.0.1 -P6032 -e "SAVE MYSQL USERS TO DISK;"
}

function fetch_credentials_from_ssm {
    SSM_MYUSER=$(aws ssm get-parameter --name "/photos-api/photos-${ENVIRONMENT}/parameters/mysql/main/username" --with-decryption --region us-east-1 | jq ".Parameter.Value" | sed 's/"//g')
    SSM_MYPWD=$(aws ssm get-parameter --name "/photos-api/photos-${ENVIRONMENT}/parameters/mysql/main/password" --with-decryption --region us-east-1 | jq ".Parameter.Value" | sed 's/"//g' | sed "s/'//g")

}

function fetch_credentials_from_prxql {
    PRXQL_MYUSER=$(mysql -uadmin -padmin -h127.0.0.1 -P6032 -NBe "SELECT variable_value FROM global_variables WHERE variable_name='mysql-monitor_username';")
    PRXQL_MYPWD=$(mysql -uadmin -padmin -h127.0.0.1 -P6032 -NBe "SELECT variable_value FROM global_variables WHERE variable_name='mysql-monitor_password';")
}

echo "USERS: '${SSM_MYUSER}' - '${PRXQL_MYUSER}'"
echo "PWDS : '${SSM_MYPWD}' - '${PRXQL_MYPWD}'"

fetch_credentials_from_ssm
update_credentials $SSM_MYUSER $SSM_MYPWD

while sleep 3600
do
    echo "Monitoring MySQL Credentials for changes..."

    fetch_credentials_from_ssm
    fetch_credentials_from_prxql

    if [ "${SSM_MYUSER}" != "${PRXQL_MYUSER}" ]; then
      update_credentials $SSM_MYUSER $SSM_MYPWD
    else
        if [ "${SSM_MYPWD}" != "${PRXQL_MYPWD}" ]; then
          update_credentials $SSM_MYUSER $SSM_MYPWD
        fi
    fi

done
