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

```
Running 10s test @ http://localhost:3000/shorten/test
  2 threads and 10 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency   276.89us  117.96us   3.35ms   95.30%
    Req/Sec    18.09k     0.93k   19.50k    77.23%
  363541 requests in 10.10s, 52.70MB read
  Non-2xx or 3xx responses: 363541
Requests/sec:  35994.92
Transfer/sec:      5.22MB

=== Status Code Summary ===
Total requests: 363541
```