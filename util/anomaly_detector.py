from __future__ import print_function
import os
import sys

path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(path)

import mgof

def main(key):
    a = mgof.AnomalyDetector()
    print("Valid interval (tukey): ", a.tukey_range(key))
    anomaly = a.is_window_anomalous(key, confidence=95)
    print("Anomaly (confidence 95%): ", anomaly)

if __name__ == "__main__":
    main(sys.argv[1])
