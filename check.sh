#!/bin/bash
set -e
res=tensorflow
wait=false

help_message="Usage: $0 [opts] [x22|x27|...|x34|x35, default: local]
 e.g.: $0 x35
Options
  --res <tensorflow|gpu>   default: tensorflow
  --wait <true|false>      default: false"
. parse_options.sh

if [ $# -gt 1 ]; then
  echo "$help_message"
  exit 1;
elif [ $# -eq 1 ]; then
  q=${1}.q
else
  q=$(hostname | sed 's/server//').q
fi

stat=`qstat -F $res -q $q -r` ||\
  (echo "$0: Cannot get state of q. Possibly nonexistent q '$q'."; exit 1;)
available=$(echo "$stat" | sed -n '4p' | grep -Po '(?<=hc:'$res'=)\S+$') ||\
  (echo "$0: Unknown error"; exit 1;)

wait_min=0
while [ $available -eq 0 ]; do
  qjobs=$(echo "$stat" | sed '1,4d')
  echo "############################################################################"
  echo " - Running Jobs - Running Jobs - Running Jobs - Running Jobs - Running Jobs"
  echo "############################################################################"
  echo "$qjobs"
  ! $wait && exit 123; 
  echo "############################################################################"
  echo -e "Waiting... (${wait_min} min)\n"
  sleep 60
  stat=`qstat -F $res -q $q -r`
  available=$(echo "$stat" | sed -n '4p' | grep -Po '(?<=hc:'$res'=)\S+$')
  wait_min=$[wait_min+1]
  clear
done
echo "$0: $res on $q is available now."
exit 0


