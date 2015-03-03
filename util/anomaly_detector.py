from __future__ import print_function
import argparse
import os
import sys

path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(path)

import mgof

parser = argparse.ArgumentParser(description='Detect anomaly')
parser.add_argument('key', type=str,
                   help='redis key')
parser.add_argument('--redis_host', "-r", type=str, default="localhost",
                    help='redis host')
parser.add_argument('--redis_port', "-p", type=int, default=6379,
                   help='redis port')
parser.add_argument('--socket_timeout', "-t", type=int, default=30,
                    help='redis socket timeout')
parser.add_argument('--n_bins', "-n", type=int, default=10,
                   help='number of bins')
parser.add_argument('--min_value', "-i", type=int, default=0,
                   help='min value of time series')
parser.add_argument('--max_value', "-x", type=int, default=1,
                   help='min value of time series')
parser.add_argument('--window_size', "-w", type=int, default=60,
                   help='window size')
parser.add_argument('--confidence', "-c", type=float, default=95,
                   help='confidence level (95, 99, or 99.5)')


def main(key):
    args = parser.parse_args()
    detector = mgof.AnomalyDetector(
        host=args.redis_host,
        port=args.redis_port,
        socket_timeout=args.socket_timeout)
    anomaly = detector.is_window_anomalous(key,
        n_bins=args.n_bins,
        min_value=args.min_value,
        max_value=args.max_value,
        window_size=args.window_size,
        confidence=args.confidence)
    print("Anomaly (confidence {}%): {}".format(args.confidence, anomaly))

if __name__ == "__main__":
    main(sys.argv[1])
