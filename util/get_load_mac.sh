while true
LOAD=`sysctl -n vm.loadavg | awk '{print $2}'`

do
    python -c "import mgof; a = mgof.AnomalyDetector(); a.post_metric('load', $LOAD)"
    echo $LOAD
    sleep 1
done
