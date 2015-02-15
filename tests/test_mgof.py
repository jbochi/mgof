import mgof
import pytest
import redis
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
