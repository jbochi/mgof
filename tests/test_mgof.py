import mgof
import pytest
import redis
import random
import time


TEST_KEY = "test_key"
r = redis.StrictRedis(host='localhost', port=6379)


def setup_function(function):
    r.delete(TEST_KEY)


@pytest.fixture
def a():
    return mgof.AnomalyDetector()


def test_post_ang_get_metric_back(a):
    a.post_metric(key=TEST_KEY, value=40.0, timestamp=14000000)
    assert a.get_time_series(key=TEST_KEY) == [(14000000, 40.0)]


def test_should_use_current_timestamp_for_metric(a):
    now = time.time()
    a.post_metric(key=TEST_KEY, value=10.0)
    assert abs(a.get_time_series(key=TEST_KEY)[0][0] - now) < 0.5


def test_get_metric_should_return_values_in_specified_range(a):
    ts = 14000000
    a = mgof.AnomalyDetector()
    a.post_metric(key=TEST_KEY, value=40.0, timestamp=ts)

    assert a.get_time_series(key=TEST_KEY) == [(ts, 40.0)]
    assert a.get_time_series(key=TEST_KEY, start=ts - 10, stop=ts + 10) == [(ts, 40.0)]
    assert a.get_time_series(key=TEST_KEY, start="-inf", stop="+inf") == [(ts, 40.0)]
    assert a.get_time_series(key=TEST_KEY, start=ts - 20, stop=ts - 10) == []
    assert a.get_time_series(key=TEST_KEY, start=ts + 10, stop=ts - 20) == []


def test_should_timeseries_values_in_order(a):
    now = time.time()
    a.post_metric(key=TEST_KEY, value=40.0, timestamp=now)
    a.post_metric(key=TEST_KEY, value=20.0, timestamp=now - 60)
    assert a.get_time_series(key=TEST_KEY) == [(now - 60, 20.0), (now, 40.0)]


def test_should_delete_old_values(a):
    now = time.time()
    a.post_metric(key=TEST_KEY, value=40.0, timestamp=now)
    a.post_metric(key=TEST_KEY, value=20.0, timestamp=now - 60)
    a.clean_old_values(key=TEST_KEY, series_length=30.0)
    assert a.get_time_series(key=TEST_KEY) == [(now, 40.0)]


def test_should_detect_anomalies(a):
    now = int(time.time())
    for ts in range(now - 600, now - 60):
        value = random.normalvariate(mu=50.0, sigma=10.0)
        a.post_metric(key=TEST_KEY, value=value, timestamp=ts)
    for ts in range(now - 60, now):
        value = random.normalvariate(mu=75.0, sigma=1.5)
        a.post_metric(key=TEST_KEY, value=value, timestamp=ts)
    assert a.is_window_anomalous(key=TEST_KEY, window_size=60)
