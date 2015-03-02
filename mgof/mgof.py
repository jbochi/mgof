import os
import redis
import time
import types
import re


class AnomalyDetector():
    def __init__(self, host='localhost', port=6379, socket_timeout=5):
        self.r = redis.StrictRedis(
            host=host,
            port=port,
            socket_timeout=socket_timeout)
        self.async_available = self._async_available()
        self.post_metric_script = self._load_script("post_metric", async=False)
        self.tukey_script = self._load_script("tukey")
        self.window_anomaly_script = self._load_script("mgof")
        self.get_values_script = self._load_script("get_values")
        self.anomalous_windows_script = self._load_script("anomalies")

    def _async_available(self):
        available = False
        try:
            self.r.execute_command("EVALSHAASYNC")
        except redis.exceptions.ResponseError as e:
            available = (e.message == "wrong number of arguments for 'evalshaasync' command")
        if not available:
            print("WARNING: Async scripts disabled. Use parallel redis!")
        return available

    def _register_async_script(self, script):
        return AsyncScript(self.r, script)

    def _get_script_content(self, script_name):
        with open(os.path.join("scripts", script_name + ".lua")) as f:
            content = f.read()
        #TODO: More general replacement for other module names
        if script_name != "utils":
            utils_content = self._get_script_content("utils")
            utils_content_without_return = "\n".join(utils_content.split("\n")[:-2])
            content = content.replace('local utils = require("utils")\n',
                utils_content_without_return)
        return content

    def _load_script(self, script_name, async=True):
        async = self.async_available and async
        content = self._get_script_content(script_name)
        if async:
            return self._register_async_script(content)
        else:
            return self.r.register_script(content)

    def post_metric(self, key, value, timestamp=None):
        timestamp = timestamp or time.time()
        return self.post_metric_script(keys=[key], args=[str(timestamp), str(value)])

    def get_time_series(self, key, start="-inf", stop="+inf"):
        elements = self.get_values_script(keys=[key], args=[start, stop])
        return map(lambda x: map(float, x), elements)

    def clean_old_values(self, key, series_length):
        now = time.time()
        return self.r.zremrangebyscore(key, "-inf", now - series_length)

    def is_window_anomalous(self, key, min_value=None, max_value=None,
        n_bins=10, window_size=60, confidence=99, c_th=1):
        return self.window_anomaly_script(keys=[key],
            args=[min_value, max_value, n_bins, window_size, confidence, c_th]) == 1

    def anomalous_windows(self, key):
        return self.anomalous_windows_script(keys=[key])

    def tukey_range(self, key, k=1):
        """Returns the min and max alert thresholds for a given k (# of stddev tolerance)"""
        return map(float, self.tukey_script(keys=[key], args=[k]))


class AsyncScript(redis.client.Script):
    def __call__(self, keys=[], args=[], client=None):
        if client is None:
            client = self.registered_client
        def eval_async(self, sha, numkeys, *keys_and_args):
            return self.execute_command('EVALSHAASYNC', sha, numkeys, *keys_and_args)
        client.evalsha = types.MethodType(eval_async, client)
        return super(AsyncScript, self).__call__(keys, args, client)
