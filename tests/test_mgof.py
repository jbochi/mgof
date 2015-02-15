import mgof
import redis

TEST_KEY = "test_key"
r = redis.StrictRedis(host='localhost', port=6379)

def test_insert_data():
    a = mgof.AnomalyDetector()
    r.delete(TEST_KEY)
    a.post_metric(key=TEST_KEY, value=40.0, timestamp=14000000)
    r.zcount(TEST_KEY, "-inf", "inf") == 1
