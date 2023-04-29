#!/bin/bash

while ! pg_isready -q -p 5432 -U $db_user -h db
do
  echo "$(date) - waiting for database to start"
  sleep 2
done

./bin/migrate
./bin/server
