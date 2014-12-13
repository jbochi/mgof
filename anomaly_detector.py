from __future__ import print_function
import redis


r = redis.StrictRedis(host='localhost', port=6379)
tukey_script = r.register_script("""
    local key = KEYS[1]
    local k = ARGV[1] or 1.5
    local time_series_to_values = function(time_series)
        for i = 1, #time_series do
            local value = string.gsub(time_series[i], "%d+:", "")
            time_series[i] = tonumber(value)
        end
        return time_series
    end
    local elements = time_series_to_values(redis.call('ZRANGEBYSCORE', key, '-inf', '+inf'))
    if #elements < 4 then
        return false
    end
    table.sort(elements)
    local q1 = elements[math.floor(#elements / 4)]
    local q3 = elements[math.floor(#elements / 4 * 3)]
    local lt = q1 - k * (q3 - q1)
    local ut = q3 + k * (q3 - q1)
    return {tostring(lt), tostring(ut)}
""")


window_anomaly_script = r.register_script("""
    local key = KEYS[1]
    local n_bins = tonumber(ARGV[1]) or 10
    local w_size = tonumber(ARGV[2]) or 60
    local confidence = 0.99
    local chi_square = {[0.99]={[9]=23.21}}
    local create_classifier = function(time_series, n_bins)
        local min
        local max
        for i = 1, #time_series do
            if min == nil or time_series[i] < min then
                min = time_series[i]
            end
            if max == nil or time_series[i] > max then
                max = time_series[i]
            end
        end
        local step_size = (max - min) / n_bins
        local classifier = function(value)
            return math.max(1, math.ceil((value - min) / step_size))
        end
        print("MAX", "MIN", "STEP")
        print(max, min, step_size)
        return classifier
    end
    local distribution = function(time_series, n_bins, classifier)
        local p = {}
        for i = 1, n_bins do
            p[i] = 0
        end
        for i = 1, #time_series do
            local bin = classifier(time_series[i])
            p[bin] = p[bin] + 1
        end
        for i = 1, n_bins do
            p[i] = p[i] / #time_series
        end
        return p
    end
    local time_series_to_values = function(time_series)
        for i = 1, #time_series do
            local value = string.gsub(time_series[i], "%d+:", "")
            time_series[i] = tonumber(value)
        end
        return time_series
    end
    local relative_entropy = function(q, p)
        local total = 0
        for i = 1, #q do
            if q[i] > 0 then
                total = total + q[i] * math.log(q[i] / p[i])
            end
            print(i, tostring(q[i]), tostring(p[i]), tostring(total))
        end
        return total
    end
    local likelihood_ratio = function(p_observed, p)
        local n = #p_observed
        return n * relative_entropy(p_observed, p)
    end
    local chi_square_test_value = function(p_observed, p)
        return 2 * likelihood_ratio(p_observed, p)
    end
    local chi_square_test = function(test_value, k, confidence)
        local cdf = chi_square[confidence][k]
        assert(cdf ~= nil, "unknown cdf distribution")
        if test_value > cdf then return 1 else return 0 end
    end
    local elements = time_series_to_values(redis.call('ZRANGEBYSCORE', key, '-inf', '+inf'))
    local window   = time_series_to_values(redis.call('ZREVRANGEBYSCORE', key, '+inf', '-inf', 'LIMIT', 0, w_size))
    local classifier = create_classifier(elements, n_bins)
    local p = distribution(elements, n_bins, classifier)
    local p_observed = distribution(window, n_bins, classifier)
    local test_value = chi_square_test_value(p_observed, p)
    local anomaly = chi_square_test(test_value, n_bins - 1, confidence)
    return {tostring(test_value), anomaly}
""")


def tukey(key, k=1):
    """Returns the min and max alert thresholds for a given k (stddev tolerance)"""
    return tukey_script(keys=[key], args=[k])


def window_anomaly(key, n_bins=10, window_size=100):
    """Returns the probability that the last window is anomalous"""
    return window_anomaly_script(keys=[key], args=[n_bins, window_size])


def main():
    key = "load"
    print("Valid distribution (tukey): ", tukey(key))
    test, anomaly = window_anomaly(key)
    print("Chi-squared test that the last window is anomaly: ", test)
    print("Anomaly: ", anomaly != 0)


if __name__ == "__main__":
    main()
