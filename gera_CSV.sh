#!/bin/bash
fecha=`date "+%Y%m%d_%H00" -d "1 hour ago"`
file=/opt/script/reportelojas/reportes/$fecha.csv
header=`ls /opt/script/reportelojas/logs/*.csv | tail -n 24| awk -F"_" '{print substr($2 lenght,1,2)}'| tr '\n' ';'`
echo "PDV;$header" >> $file
while read line; do
        pdv=`echo $line | awk -F";" '{print $3}'`
        values=`ls  /opt/script/reportelojas/logs/*.csv | tail -n 24 |xargs grep -w $pdv | awk -F";" '{print $3}' | tr '\n' ';'`
        echo "$pdv;$values" >>  $file
done < /opt/script/reportelojas/lojas.txt

ftp -n xxx.xxx.xx.xx << EOF
user <USER> <PASS>
lcd /opt/script/reportelojas/reportes
cd PDVs
cd Export_Dufry
put $fecha.csv
cd Lojas
lcd /opt/script/reportelojas/
put lojas.txt
bye
EOF
