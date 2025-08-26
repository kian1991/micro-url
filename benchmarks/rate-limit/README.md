# Rate Limit Benchmark

This benchmark stresses a service with wrk to verify rate limiting and bench performance.

## Run

```bash
cd benchmarks/rate-limit
./run.sh http://localhost:3000/health 10s 2 10
```

- `URL`: The target URL to benchmark (default: `http://localhost:3000/health`).
- `DURATION`: Duration of the benchmark (default: `10s`).
- `THREADS`: Number of threads to use (default: `2`).
- `CONNECTIONS`: Number of connections to use (default: `10`).

## Example Output

### No Rate Limiting

```
Running 10s test @ http://api.murl.pw/health
  2 threads and 10 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    23.21ms    1.11ms  30.58ms   72.55%
    Req/Sec   215.16     21.34   252.00     76.50%
  4310 requests in 10.06s, 618.72KB read
Requests/sec:    428.32
Transfer/sec:     61.49KB

=== Status Code Summary ===
Total requests: 4310

2xx responses: 4310
4xx responses: 0
```

### With Rate Limiting (5 req/s)

```
Running 10s test @ http://api.murl.pw/health
  2 threads and 10 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    24.95ms    7.27ms 179.73ms   98.51%
    Req/Sec   202.84     19.30   240.00     76.50%
  4063 requests in 10.06s, 695.52KB read
  Non-2xx or 3xx responses: 3964
Requests/sec:    403.91
Transfer/sec:     69.14KB

=== Status Code Summary ===
Total requests: 4063

2xx responses: 99
4xx responses: 3964
```



## Benchmark Comparison

| Scenario                      | Requests/sec | Avg Latency | Successful (2xx) | Rejected (4xx) |
|-------------------------------|--------------|-------------|------------------|---------------|
| No Rate Limiting              | 428.32       | 23.21ms     | 4310             | 0             |
| With Rate Limiting (5 req/s)  | 403.91       | 24.95ms     | 99               | 3964          |

The table above shows that enabling rate limiting sharply reduces the number of successful requests (2xx responses) while most excess requests are rejected (4xx responses). Average latency remains similar, but the rate limiting middleware effectively controls request throughput and protects the service from overload.