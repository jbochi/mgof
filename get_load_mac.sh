while true; do echo "ZADD load `date +'%s'` `date +'%s'`:`sysctl -n vm.loadavg | awk '{print $2}'`" |  xargs -t redis-cli; sleep 1; done
