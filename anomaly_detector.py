from __future__ import print_function
import redis
import os

r = redis.StrictRedis(host='localhost', port=6379)


def load_script(script_name):
    with open(os.path.join("scripts", script_name + ".lua")) as f:
        return r.register_script(f.read())


tukey_script = load_script("tukey")
window_anomaly_script = load_script("mgof")


def tukey(key, k=1):
    """Returns the min and max alert thresholds for a given k (stddev tolerance)"""
    return map(float, tukey_script(keys=[key], args=[k]))


def window_anomaly(key, n_bins=10, window_size=60, confidence=95, c_th=2, debug=False):
    """Returns the probability that the last window is anomalous"""
    return window_anomaly_script(keys=[key], args=[n_bins, window_size, confidence, c_th, debug])


def main():
    key = "load"
    print("Valid internval (tukey): ", tukey(key))
    anomaly, test_value = window_anomaly(key)
    print("Chi-squared test for last window being anomalous: ", test_value)
    print("Anomaly (confidence 95%): ", anomaly != 0)


if __name__ == "__main__":
    main()
