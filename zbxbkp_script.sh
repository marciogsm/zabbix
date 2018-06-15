Thank you very much for the script.

I created a mysql user with just SELECT privileges on my Zabbix 1.8 database, just so that I can be assured that the script won't be able to accidentally lock my tables:
Code:
create user 'zabbixbackup'@'localhost' identified by 'zabbixbackup';
grant select on zabbix18.* to 'zabbixbackup'@'localhost';
I then added an argument to the mysqldump command-line so that it does not try to lock the tables either, as well as gzipping the results to a date specific filename:
Code:
#!/bin/sh
# backup zabbix config only

DBNAME=zabbix18
DBUSER=zabbixbackup
DBPASS=zabbixbackup

BK_DEST=/root/backups/

# zabbix schema
mysqldump -u$DBUSER  -p"$DBPASS" -B "$DBNAME" --no-data --skip-lock-tables | /bin/gzip -9 -c > "$BK_DEST/$DBNAME-`date +%Y-%m-%d`-schema.sql.gz"

# zabbix config
mysqldump -u"$DBUSER"  -p"$DBPASS" -B "$DBNAME" --single-transaction --skip-lock-tables --no-create-info --no-create-db \
    --ignore-table="$DBNAME.acknowledges" \
    --ignore-table="$DBNAME.alerts" \
    --ignore-table="$DBNAME.auditlog" \
    --ignore-table="$DBNAME.auditlog_details" \
    --ignore-table="$DBNAME.escalations" \
    --ignore-table="$DBNAME.events" \
    --ignore-table="$DBNAME.history" \
    --ignore-table="$DBNAME.history_log" \
    --ignore-table="$DBNAME.history_str" \
    --ignore-table="$DBNAME.history_str_sync" \
    --ignore-table="$DBNAME.history_sync" \
    --ignore-table="$DBNAME.history_text" \
    --ignore-table="$DBNAME.history_uint" \
    --ignore-table="$DBNAME.history_uint_sync" \
    --ignore-table="$DBNAME.dhosts" \
    --ignore-table="$DBNAME.dservices" \
    --ignore-table="$DBNAME.proxy_history" \
    --ignore-table="$DBNAME.proxy_dhistory" \
    --ignore-table="$DBNAME.trends" \
    --ignore-table="$DBNAME.trends_uint" \
    | /bin/gzip -9 -c > "$BK_DEST/$DBNAME-`date +%Y-%m-%d`-config.sql.gz"

And then lastly I added a cron entry to execute my script every morning 01:00.

This script of yours works, but I haven't tried to import it yet.

#### I execute the script to retrieve the zabbix configuration.
#### To restore first I removed everything, then I joined the scheme with the command
mysql --user=user --password=password db_name < /path/of/database-schema.sql

####And finally I joined the zabbix table with the command
mysql --user=user --password=password db_name < /path/of/database.sql


sed -i 's/INSERT INTO `\(.*\)` VALUES/REPLACE INTO `\1` VALUES/g' /path/of/database.sql


You'll get that error because there are already data in that table.

You can either replace the statements like
Code:
LOCK TABLES `x` WRITE;
with
Code:
TRUNCATE TABLE `x`; 'LOCK TABLES `x` WRITE;
, which you can do with the following command:
Code:
sed -i 's/LOCK TABLES `\(.*\)`/TRUNCATAE TABLE `\1`; LOCK TABLES `\1`/g' /path/of/database.sql

or

you can replace the
Code:
INSERT INTO `x` VALUES
with
Code:
REPLACE INTO `x` VALUES
, which you can do with the following command:
Code:
sed -i 's/INSERT INTO `\(.*\)` VALUES/REPLACE INTO `\1` VALUES/g' /path/of/database.sql
