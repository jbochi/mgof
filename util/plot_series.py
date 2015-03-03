import argparse
from datetime import datetime
import os
import sys
import matplotlib.pyplot as plt
import pandas as pd

path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(path)
import mgof

parser = argparse.ArgumentParser(description='Plot data')
parser.add_argument('key', type=str,
                   help='redis key')
parser.add_argument('--redis_host', "-r", type=str, default="localhost",
                    help='redis host')
parser.add_argument('--redis_port', "-p", type=int, default=6379,
                   help='redis port')
parser.add_argument('--agg_period', "-a", type=str, default="5min",
                   help='redis port')
parser.add_argument('--agg_how', "-w", type=str, default="mean",
                   help='redis port')

def to_df(series, name, agg_period, agg_how):
    timestamps = [datetime.fromtimestamp(time) for time, _ in series]
    values = [v for _, v in series]
    df = pd.DataFrame(values, index=timestamps,columns=[name])
    avgs = df.resample(agg_period, how=agg_how)
    return avgs

def main():
    args = parser.parse_args()
    detector = mgof.AnomalyDetector(host=args.redis_host, port=args.redis_port)
    series = detector.get_time_series(args.key)
    anomalies = [map(datetime.fromtimestamp, r) for r in detector.anomalous_windows(args.key)]
    df = to_df(series, args.key, args.agg_period, args.agg_how)
    max_value = df.max()[args.key]

    def is_anomaly(t):
        if any(s <= t <= e for s, e in anomalies):
            return max_value
        return 0

    df["anomaly"] = [is_anomaly(t) for t in df.index]

    df.plot()
    plt.show()


if __name__ == "__main__":
    main()
