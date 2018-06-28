select pdv,DATE_FORMAT((data),'%Y-%m-%d %H:00:00'), truncate((sum(status)/count(*)*100),2) from pdv_data
where data >= DATE_FORMAT((NOW() - INTERVAL 1 HOUR),'%Y-%m-%d %H:00:00')
and data < DATE_FORMAT(NOW(),'%Y-%m-%d %H:00:00')
group by pdv
INTO OUTFILE '/tmp/output.csv'
FIELDS TERMINATED BY ';'
LINES TERMINATED BY '\n';
