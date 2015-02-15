import os
import redis
import time
import types



class AnomalyDetector():
    def __init__(self, host='localhost', port=6379):
        self.r = redis.StrictRedis(host=host, port=port)
        # tukey_script = load_script("tukey")
        self.window_anomaly_script = self._load_script("mgof")

    def _register_async_script(self, script):
        return AsyncScript(self.r, script)

    def _load_script(self, script_name):
        with open(os.path.join("scripts", script_name + ".lua")) as f:
            return self._register_async_script(f.read())

    def _serialize_value(self, timestamp, value):
        return "%f:%f" % (timestamp, value)

    def _read_value(self, string):
        ts, value = string.split(":")
        return float(ts), float(value)

    def post_metric(self, key, value, timestamp=None):
        timestamp = timestamp or time.time()
        return self.r.zadd(key, timestamp, self._serialize_value(timestamp, value))

    def get_time_series(self, key, start="-inf", stop="+inf"):
        return map(self._read_value, self.r.zrangebyscore(key, start, stop))

    def clean_old_values(self, key, series_length):
        now = time.time()
        return self.r.zremrangebyscore(key, "-inf", now - series_length)

    def is_window_anomalous(self, key, n_bins=10, window_size=60, confidence=95, c_th=2, debug=False):
        return self.window_anomaly_script(keys=[key],
            args=[n_bins, window_size, confidence, c_th, debug])[0] == 1


class AsyncScript(redis.client.Script):
    def __call__(self, keys=[], args=[], client=None):
        if client is None:
            client = self.registered_client
        def eval_async(self, sha, numkeys, *keys_and_args):
            return self.execute_command('EVALSHAASYNC', sha, numkeys, *keys_and_args)
        client.evalsha = types.MethodType(eval_async, client)
        return super(AsyncScript, self).__call__(keys, args, client)
