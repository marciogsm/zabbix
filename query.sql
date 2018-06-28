select CONCAT(';;',host) AS HOST from zabbix.hosts where host like 'HOSTNAME_%' and status=0 order by host;
