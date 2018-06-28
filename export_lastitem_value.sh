origem=/etc/zabbix/reportscript
while read line;
do  arquivo=`echo "$line"|cut -d";" -f1`;
    arquivo=`date -d "-1 day" +%Y%m%d`$arquivo'.txt';
    grupo=`echo "$line"|cut -d";" -f2`;
    metrica=`echo "$line"|cut -d";" -f3`;
    if ! [ -e "$destino/$arquivo" ]
    then
        "$origem/export_lastitem_value.py" -g "$grupo" -k "$metrica" >> "$origem                                                                                        /$grupo";
    else
       echo "O arquivo ja existe: $destino/$arquivo"

    fi
done < "$origem/metricas_delete.txt"
