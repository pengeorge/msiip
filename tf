#!/bin/bash
# Request local TensorFlow and execute a command
# TODO fix issue: always exit with code 143

local_only=true
quiet=true
log=

help_message="Usage: $0 [opts] <command>
 e.g.: $0 --log mylog.txt sleep 60
Options
  --local-only <true|false>   if true, only use local TensorFlow
                              (default: true)
  --quiet <true|false>        if true, only outputs of the user command will be output
                              (default: true)
  --log <log-file-name>       default: log/job_YYYYmmddHHMMSS.log"

. parse_options.sh

if [ $# -eq 0 ]; then
  echo "$help_message" >&2
  exit 1;
fi

cmd="$@"

if $quiet; then
  odes='/dev/null'
else
  odes='&2'
fi
eval "echo \"$cmd\" >$odes"

check_output=`check.sh --res tensorflow --wait false`
ret=$?
set -e
time_str=`date '+%Y%m%d%H%M%S'`
logdir=qlog
[ -z "$log" ] && log="./$logdir/job_${time_str}.log" && mkdir -p $logdir
[ -f $log ] && echo "$0: $log existed." && exit 1;
if [ $ret == 123 ]; then # local not available
  echo -e "$check_output\n" >&2
  echo "Local TensorFlow is not available." >&2
  if $local_only; then
    echo "Try '$0 --local-only false <log-file> <command>'" >&2
    exit 1;
  else
    echo "Submitting to queue..."
    queue.pl --tf 1 $log $cmd
  fi
elif [ $ret == 0 ]; then # local available
  mkdir -p $logdir/q
  req_logfile=$logdir/request_tensorflow_on_$(hostname | sed 's/server//')_${time_str}.log # to get jod_id here
  trap "
  #jobs -p / jobs -pr / echo \$req_pid   (equivalent)
  job_id=\`head -n 1 ${logdir}/q/$(basename $req_logfile) | grep -Po '(?<=^Your job )\d+'\` ||\
    echo 'Cannot get job_id, please qdel manually.'
  #ps aux | grep \`jobs -p\`
  #ps aux | grep $$
  #trap - SIGTERM && kill -- \`jobs -p\`
  #trap - SIGTERM && qdel \$job_id && kill -- -$$
  trap - SIGTERM && qdel \$job_id >$odes && kill 0
  " EXIT SIGINT SIGTERM

  shfile=${logdir}/q/$(basename $log).sh
  echo -e "#!/bin/bash\n$cmd\n" > $shfile
  eval "request --logfile $req_logfile >$odes" ||\
    echo "Error in requesting (code: $?), command is still running but resource occupation is not recorded." >&2 &
  req_pid=$!
  sleep 1
  eval "echo >$odes"
  echo "# Started at `date`" > $log
  bash $shfile | tee -a $log
  echo "# Finished at `date`" >> $log
  echo "Done. log was saved in $log" >&2
else
  echo "$0: Unknown error" >&2
  exit 1;
fi

