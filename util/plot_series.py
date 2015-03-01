import os
import sys

path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(path)

import datetime
import matplotlib.pyplot as plt
import mgof

detector = mgof.AnomalyDetector()
series = detector.get_time_series("load")

timestamps = [datetime.datetime.fromtimestamp(time) for time, _ in series]
values = [v for _, v in series]

plt.plot(timestamps, values)
plt.show()

