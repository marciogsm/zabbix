if [ -f /tmp/output.csv ]; then
        rm -f /tmp/output.csv
fi

mysql reportePDV < /opt/script/reportelojas/getData.sql
mv /tmp/output.csv /opt/script/reportelojas/logs/`date "+%Y%m%d_%H%M%S" -d "1 hour ago"`.csv
