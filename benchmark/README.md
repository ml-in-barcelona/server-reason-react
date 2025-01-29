# Benchmark

The benchmark doesn't represent a real world usage of the framework, but it's a closer approximation.

It is running a simple web server that renders some React tree and responds with a stringified HTML. Consists of 1) node + express, 2) bun and 3) dream with server-reason-react.

The application uses the same React tree in all 3 cases, so the differences are:

- runtime
- ReactDOM's implementation
- server framework (if any)

It's based on 384cd79c73be5baddf281b9a089bbf843e1b990d and not what's currently on main.

## Running the benchmark

Command to run `wrk -t8 -c400 -d30s http://localhost:xxxx`

## Results

### node-express-js

  ```cd benchmark/node-express-js; NODE_ENV=production node index.js```

```sh
    Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    30.89ms   11.23ms 206.66ms   93.11%
    Req/Sec     1.66k   321.02     2.02k    81.42%
  396545 requests in 30.09s, 524.91MB read

Requests/sec:  13176.71
Transfer/sec:     17.44MB
```

### bun-js

  ```cd benchmark/bun-js; NODE_ENV=production ~/bun/bin/bun run index.js```

```sh
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    22.85ms    5.24ms 120.22ms   95.59%
    Req/Sec     0.88k   492.74     2.31k    50.77%
  315018 requests in 30.10s, 257.46MB read

Requests/sec:  10464.64
Transfer/sec:      8.55MB
```

### dream-reason-native

  ```make build-server-prod; _build/default/server/server.exe```

```sh
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     6.15ms  598.15us  23.92ms   97.05%
    Req/Sec     8.17k     1.40k   75.44k    98.63%
  1951327 requests in 30.10s, 5.18GB read

Requests/sec:  64822.31
Transfer/sec:    176.12MB
```
