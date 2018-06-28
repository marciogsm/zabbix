fecha=`date "+%Y-%m-%d %H:%M:%S"`
echo "Inicio Proceso" >> /opt/script/reportelojas/logs/check_lojas.log
echo $fecha >> /opt/script/reportelojas/logs/check_lojas.log
mysql -sN -e "select CONCAT(';;',host) AS HOST from zabbix.hosts where host like 'PDV_%' and status=0 order by host;" > /opt/script/reportelojas/lojas.txt
while read line;
do
                ip=`echo $line | awk -F";" '{print $1}'`
                loja=`echo $line | awk -F";" '{print $2}'`
                nome=`echo $line | awk -F";" '{print $3}'`
                uf=`echo $line | awk -F";" '{print $4}'`
                tipo=`echo $line | awk -F";" '{print $5}'`
                #comando=`ping -c1 -W1 $ip`
                #salida=`echo $?`
                #if [ $salida -eq 0 ];then
                #        statusloja=1
                #else
                #        statusloja=0
                #fi

                #ROTINA DE PING COMENTADA DIA 31-05 AS 01H23 PARA BUSCA DE RESULTADO DO PDV NO ZABBIX
                #LINHA ABAIXO SE REFERE A BUSCA DO ULTIMO RESULTADO DE PING NO ZABBIX
                statusloja=`/opt/script/reportelojas/buscaNoZabbix.sh $nome | /usr/bin/bc`

echo $nome
echo $fecha
echo $statusloja

                #echo "$ip;$loja;$nome;$uf;$tipo;$statusloja" >> /opt/script/reportelojas/logs/$fecha.log
mysql << EOFMYSQL
        INSERT INTO reportePDV.pdv_data ( pdv , data , status) VALUES ( '$nome' , '$fecha' , $statusloja );
EOFMYSQL
done < /opt/script/reportelojas/lojas.txt


#/usr/bin/expect << EOD
#spawn ftp 200.202.42.16
#expect "Name (200.202.42.16:root):"
#send "ftpdufry\r"
#expect "Password:"
#send "ftpdufry@123\r"
#expect "ftp>"
#send "lcd /opt/script/reportelojas/logs\r"
#expect "Local directory now /opt/script/reportelojas/logs"
#expect "ftp>"
#send "put $fecha.log"
#expect "ftp>"
#end "bye\r"
#nteract
#OD
#cho $fecha >> /opt/script/reportelojas/logs/check_lojas.log
#cho "###################################################" >> /opt/script/reportelojas/logs/check_lojas.log
