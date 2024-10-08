#!/bin/bash
# Script Name: zabbix_network_diagnostics.sh
# Description: Diagnoses network issues related to Zabbix proxy communication.
# Usage: ./zabbix_network_diagnostics.sh <file> [timeout]
#        <file> - A file containing a list of IP addresses to check.
#        [timeout] - (Optional) Timeout value for tcpdump. Default is 60 seconds.
# Created by: Marcio Moreno
# Creation Date: 2023-07-29
#set -v

SCRIPT_DIR="/home/mgmoreno"
LOG_DIR="${SCRIPT_DIR}/logs/"

# Check if the input file is provided
if [[ $# -ge 2 ]]; then
    echo "Usage: $0 <file> [timeout]"
    exit 1
fi

if [[ ! -d ${LOG_DIR} ]]; then
        mkdir -p ${LOG_DIR}
fi

# Set Zabbix Proxy logs path
ZBXLOG="/var/log/zabbix/zabbix_proxy.log"

# Set hostname
HOST=$(hostname)

# Filter hosts by Zabbix Proxy and prepare file
grep -w -i "${HOST}" "${SCRIPT_DIR}/Controle" > "${SCRIPT_DIR}/${HOST}"

# | while IFS=";" read -r concat cust hub host ok addr os mrdmon addrproxy proxy e status g h i j k l obs gestao; do
#    echo "$cust;$addr;$proxy;$host;$os;$status;$obs;$gestao;$addrproxy"
# done > "${SCRIPT_DIR}/${HOST}"

# Print header
echo -e "Host;ADDR;ZBX_ERROR_CODE;ZBX_OUT;ICMP;Trace;ZBXProxy received connections on port 10051?;Host listening on port 10050?;ZBXProxy logs contain errors?;Issue;Gama;ZBXProxy;ZBXProxyAddr;Cust;OS;Status;OBS;Gestao;PreviousRun"

# Loop through each address in the input file
while IFS=";" read -r cust host addr proxy addrproxy os status obs gestao; do
# Check if the variables are empty and set them to "NA" if they are
[ -z "$cust" ] && cust="NA"
[ -z "$addr" ] && addr="NA"
[ -z "$proxy" ] && proxy="NA"
[ -z "$host" ] && host="NA"
[ -z "$os" ] && os="NA"
[ -z "$status" ] && status="NA"
[ -z "$obs" ] && obs="NA"
[ -z "$gestao" ] && gestao="NA"
[ -z "$addrproxy" ] && addrproxy="NA"

    # Initialize ISSUE flag
    ISSUE="No"
    ICMP_OUT="0"
    NMAP_OUT="0"
    TCPDUMP_OUT="0"

    # Initialize ZBX_GET and ZBX_OUT flags
    ZBX_GET="RESET"
    ZBX_OUT="RESET"
    ZBX_ERROR_CODE="RESET"


    # Isolate network
    GAMA=$(echo "$addr" | sed -e 's/\.[0-9]\+$/\.0\/24/g')

    # ICMP check
    ICMP=$(ping -W 0.5 -c2 "$addr" | grep -Eo '[0-9]{1,3}% \w+ \w+')
    if [[ $ICMP =~ "100" ]]; then
        #TRACE=$(tracepath -m5 "$addr" | grep -B1 -m1 'no reply' | awk 'NR==1 {print $2}')
        #TRACE=${TRACE:-"unknown"}
        #TRACE="Tracert stopped at hop $TRACE"
        TRACE="Foi igorado o Tracert para esta execucao da script"
        ISSUE="Yes"
        ICMP_OUT="1"
    else
        TRACE="Tracert ok"
    fi
if grep -q -i -w "$cust$host" ${SCRIPT_DIR}/previous; then
TCPDUMP_STATUS="Zabbix Proxy received packets on port 10051"
NMAP_STATUS="open Port 10050 on customer host"
ISSUE="No"
PREVIOUS="PreviouslyWorked"

else
PREVIOUS="TryItAgain"
# Set timeout value, default is 60 seconds
TIMEOUT=${2:-300}

    # Tcpdump check if status is not equal to "Instalado"
    if [[ "$status" == "Instalado" ]]; then
        TCPDUMP_STATUS="Zabbix Proxy received packets on port 10051"
        ISSUE="No"
    elif [[ "$status" != "Instalado" ]]; then
        TCPDUMP=$(sudo timeout ${TIMEOUT} tcpdump -c1 -nnn -vvv -i any host "$addr" and port 10051 2>&1)
        if echo "$TCPDUMP" | grep -q "$addr"; then
            TCPDUMP_STATUS="Zabbix Proxy received packets on port 10051"
        else
            TCPDUMP_STATUS="Zabbix Proxy no packets received on port 10051"
            TCPDUMP_OUT="1"
            ISSUE="Yes"
        fi
    fi

    # Nmap port check
    NMAP=$(sudo nmap -Pn "$addr" -p10050 | awk '/tcp/ {print $2}')
    if [[ $NMAP =~ "closed" || $NMAP =~ "filtered" || -z $NMAP ]]; then
        NMAP_STATUS="$NMAP Port 10050 on customer host"
        # ISSUE="Yes"  By now ignore but in the OS admins will have to realize why it doesnt answer
        timeout="1"
        NMAP_OUT="1"
    elif [[ ! $NMAP =~ "check any value to ensure is not listening on port 10060" ]]; then
    if grep -q -w -i $host "${SCRIPT_DIR}/10060"; then
        NMAP_STATUS="open Port 10050 on customer host"
        ZBX_GET="Overwrite"
        ISSUE="No"
    fi
    else
        NMAP_STATUS="open Port 10050 on customer host"
        timeout="5"
    fi
fi


[[ $timeout == "" ]] && timeout="5"

# Zabbix agent check ignore hosts with agent installed on port 10060
if [[ $ZBX_GET == "Overwrite" ]]; then
    ZBX_OUT="A escutar na porta 10060"
else
    ZBX_OUT=$(zabbix_get -t "$timeout" -s "$addr" -k agent.hostname 2>&1)
    # | awk -F': ' 'NR==1 {output=$2} NR>1 {output=output"|" $2} END {print output}')
    ZBX_ERROR_CODE="$?"

    if [[ "${ZBX_OUT,,}" =~ timeout|error|access|restrictions ]]; then
  ZBX_OUT=$(echo "$ZBX_OUT" | awk -F': ' 'NR==1 {output=$2} NR>1 {output=output"|" $2} END {print output}')
else
        ZBX_OUT=$(zabbix_get -t "$timeout" -s "$addr" -k agent.hostname)
fi

if [[ "$ICMP_OUT" == "1" && "$NMAP_OUT" == "0" && "$TCPDUMP_OUT" == "0" ]]; then
    ISSUE="FaileOnlyICMP"
fi

#    if [[ $ZBX_ERROR_CODE = "1" ]]; then
#        ISSUE="Yes"
#    fi
fi


    # Zabbix proxy log check
    IP=$(echo "$addr" | sed 's/\./\\./g')
    LOG=$(grep "$(date '+%Y%m%d')" "$ZBXLOG" | grep -m1 -w "$IP")
    if [[ $? -eq 0 ]]; then
        LOG_STATUS="Found ERROR in Zabbix Proxy LOG - $LOG"
    else
        LOG_STATUS="No errors found in Zabbix Proxy LOG"
    fi



    # Output results for the current address
    echo -e "$host;$addr;$ZBX_ERROR_CODE;$ZBX_OUT;$ICMP;$TRACE;$TCPDUMP_STATUS;$NMAP_STATUS;$LOG_STATUS;$ISSUE;$GAMA;$proxy;$addrproxy;$cust;$os;$status;$obs;$gestao;$PREVIOUS"

done < "${SCRIPT_DIR}/${HOST}"
