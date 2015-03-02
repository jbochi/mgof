import argparse
import os
import sys
import requests

path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(path)
import mgof

parser = argparse.ArgumentParser(description='Import data from graphite')
parser.add_argument('graphite_host', type=str,
                   help='graphite host')
parser.add_argument('metric', type=str,
                   help='graphite metric')
parser.add_argument('--key', "-k", type=str, default=None,
                   help='redis key')
parser.add_argument('--redis_host', "-r", type=str, default="localhost",
                    help='redis host')
parser.add_argument('--redis_port', "-p", type=int, default=6379,
                   help='redis port')

def main():
    args = parser.parse_args()
    detector = mgof.AnomalyDetector(host=args.redis_host, port=args.redis_port)
    url = "http://{graphite_host}/render/?target={metric}&format=json".format(
        graphite_host=args.graphite_host,
        metric=args.metric
    )
    datapoints = requests.get(url).json()[0]["datapoints"]
    key = args.key or args.metric
    print "Importing {} datapoints from {} to {}".format(
        len(datapoints), args.metric, key)
    for i, (value, timestamp) in enumerate(datapoints):
        if value:
            detector.post_metric(key, value, timestamp)
            if i % 50 == 0:
                sys.stdout.write(".")
                sys.stdout.flush()
    print ""

if __name__ == "__main__":
    main()
