#!/bin/sh
#Autor: Ruan Oliveira

API='http://10.131.101.15/zabbix/api_jsonrpc.php'

# CONSTANT VARIABLES
ZABBIX_USER='report_user'
ZABBIX_PASS='cap@123'

HOSTNAME=$1
STATUS=$2

echo
help() {
        echo "*****************************************"
        echo "**                                     **"
        echo "**RESGATA O ULTIMO VALOR DE PING DO PDV**"
        echo "**                                     **"
        echo "*****************************************"
        echo ENABLE 0
        echo DISABLE  1
        echo "$0 HOST ENABLE / DISABLE"
        echo
}

authenticate()
{
    wget -O- -o /dev/null $API --header 'Content-Type: application/json-rpc' --post-data "{
        \"jsonrpc\": \"2.0\",
        \"method\": \"user.login\",
        \"params\": {
                \"user\": \"$ZABBIX_USER\",
                \"password\": \"$ZABBIX_PASS\"},
        \"id\": 0}" | cut -d'"' -f8
}
AUTH_TOKEN=$(authenticate)

get_host_id() {
  wget -O- -o /dev/null $API --header 'Content-Type: application/json-rpc' --post-data "{
        \"jsonrpc\": \"2.0\",
        \"method\": \"host.get\",
        \"params\": {
        \"output\": [
                \"hostid\"
                    ],
        \"filter\": {
                \"host\" : [ \"$HOSTNAME\" ]
                }
          },
        \"auth\": \"$AUTH_TOKEN\",
        \"id\": 1}" | awk -v RS='{"' -F: '/^hostid/ {print $2}' | awk -F\" '{print $2}'
}
HOSTID=$(get_host_id);


get_item_value() {
   wget -O- -o /dev/null $API --header 'Content-Type: application/json-rpc' --post-data "{
        \"jsonrpc\": \"2.0\",
        \"method\": \"host.update\",
        \"params\": {
                \"hostid\": \"$HOSTID\",
                \"status\": \"$STATUS\"
        },
        \"auth\": \"$AUTH_TOKEN\",
        \"id\": 1}" | cut -d'"' -f22
}


ITEMVALUE=$(get_item_value);

if [ -z $1 ]; then
        echo
        help;
        else
        echo
        get_item_value;
        #get_host_id;
        echo
fi
