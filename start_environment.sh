#!/bin/bash

docker-compose up -d

sleep 5

cd proxysql

terraform init

terraform apply -auto-approve

cd -