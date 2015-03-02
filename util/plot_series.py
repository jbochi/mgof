import argparse
import datetime
import os
import sys
import matplotlib.pyplot as plt

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

def main():
    args = parser.parse_args()
    detector = mgof.AnomalyDetector(host=args.redis_host, port=args.redis_port)
    series = detector.get_time_series(args.key)

    timestamps = [datetime.datetime.fromtimestamp(time) for time, _ in series]
    values = [v for _, v in series]

    plt.plot(timestamps, values)
    plt.show()


if __name__ == "__main__":
    main()
