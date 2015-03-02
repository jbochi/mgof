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

def to_df(series, name):
    timestamps = [datetime.fromtimestamp(time) for time, _ in series]
    values = [v for _, v in series]
    df = pd.DataFrame(values, index=timestamps,columns=[name])
    avgs = df.resample('5min', how='max')
    return avgs

def main():
    args = parser.parse_args()
    detector = mgof.AnomalyDetector(host=args.redis_host, port=args.redis_port)
    series = detector.get_time_series(args.key)
    anomalies = [map(datetime.fromtimestamp, r) for r in detector.anomalous_windows(args.key)]

    df = to_df(series, args.key)
    max_value = df.max()[args.key]
    print max_value

    def is_anomaly(t):
        if any(s <= t <= e for s, e in anomalies):
            return max_value
        return 0

    df["anomaly"] = [is_anomaly(t) for t in df.index]

    plt.figure()
    df.plot()
    plt.show()


if __name__ == "__main__":
    main()
