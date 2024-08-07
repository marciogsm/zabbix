#!/bin/bash

# Script Name: zabbix_network_diagnostics.sh
# Description: This script diagnoses network issues related to Zabbix proxy communication.
# Usage: ./zabbix_network_diagnostics.sh <file> [timeout]
#        <file> - A file containing a list of IP addresses to check.
#        [timeout] - (Optional) Timeout value for tcpdump. Default is 60 seconds.

# Check if the input file is provided
if [[ -z $1 ]]; then
    echo "Usage: $0 <file> [timeout]"
    exit 1
fi

# Set timeout value, default is 60 seconds
TIMEOUT=${2:-60}

# Set Zabbix Proxy logs path
ZBXLOG="/var/log/zabbix/zabbix_proxy.log"

# Print header
echo -e "ADDR;ZBX_ERROR_CODE;ZBX_OUT;ICMP;Trace;ZBXProxy received connections on port 10051?;Host listening on port 10050?;ZBXProxy logs contain errors?;Issue"

# Loop through each address in the input file
while read -r addr; do
    # Initialize ISSUE flag
    ISSUE="No"
    
    # ICMP check
    ICMP=$(ping -W 0.5 -c2 "$addr" | grep -Eo '[0-9]{1,3}% \w+ \w+')
    if [[ $ICMP =~ "100" ]]; then
        TRACE=$(tracepath -m5 "$addr" | grep -B1 'no reply' | grep -B1 -m1 'no reply' | awk 'NR==1 {print $2}')
        TRACE=${TRACE:-"unknown"}
        TRACE="Tracert stopped at hop $TRACE"
        ISSUE="Yes"
    else
        TRACE="Tracert ok"
    fi

    # Zabbix agent check
    ZBX_OUT=$(zabbix_get -t 1 -s "$addr" -k agent.hostname 2>/dev/null)
    ZBX_ERROR_CODE="$?"

    # Tcpdump check
    TCPDUMP=$(sudo timeout ${TIMEOUT} tcpdump -c1 -nnn -vvv -i any host "$addr" and port 10051 2>&1)
    if echo "$TCPDUMP" | grep -q "$addr"; then
        TCPDUMP_STATUS="Zabbix Proxy received packets on port 10051"
    else
        TCPDUMP_STATUS="Zabbix Proxy no packets received on port 10051"
        ISSUE="Yes"
    fi

    # Nmap port check
    NMAP=$(sudo nmap -Pn "$addr" -p10050 | awk '/tcp/ {print $2}')
    if [[ $NMAP =~ "closed" || $NMAP =~ "filtered" || -z $NMAP ]]; then
        NMAP_STATUS="$NMAP Port 10050 on customer host"
        ISSUE="Yes"
    else
        NMAP_STATUS="$NMAP Port 10050 on customer host"
    fi

    # Zabbix proxy log check
    
    IP=$(echo "$addr" | sed 's/\./\\./g')
    LOG=$( grep date '+%Y%m%d' $ZBXLOG | grep -m1 -w "$IP" $ZBXLOG)
    if [[ $? -eq 0 ]]; then
        LOG_STATUS="Found ERROR Zabbix Proxy LOG - $LOG"
    else
        LOG_STATUS="Not Found ERROR Zabbix Proxy LOG"
    fi

    # Output results for the current address
    echo -e "$addr;$ZBX_ERROR_CODE;$ZBX_OUT;$ICMP;$TRACE;$TCPDUMP_STATUS;$NMAP_STATUS;$LOG_STATUS;$ISSUE"

done < "$1"
