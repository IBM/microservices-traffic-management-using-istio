#!/bin/bash
if [ -z "$MYSQL_DB_USER" ] || [ -z "$MYSQL_DB_PASSWORD" ] || [ -z "$MYSQL_DB_HOST" ] || [ -z "$MYSQL_DB_PORT" ]
then
    echo "Environment variables not found."
else
    mysql -u $MYSQL_DB_USER --password=$MYSQL_DB_PASSWORD --host $MYSQL_DB_HOST --port $MYSQL_DB_PORT < bookinfo.sql
fi

exec "$@"
