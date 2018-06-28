#/bin/bash

HOST=`mysql -sN < /home/marcio.moreno/host_list.sql`
for i in $HOST
do
  echo $i
done
