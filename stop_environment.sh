#!/bin/bash

cd proxysql

terraform destroy -auto-approve

cd -

docker-compose down -v --remove-orphans