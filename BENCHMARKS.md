# TAG Benchmarks

Benchmark results for a single TAG instance serving cached object reads.

## Test Environment

Benchmarks were run on Amazon EC2 using [go-ycsb](https://github.com/pingcap/go-ycsb).

| Role | Instance | vCPUs | Memory | Storage | Network |
|------|----------|-------|--------|---------|---------|
| Benchmark client | c6in.16xlarge | 64 | 128 GiB | - | 100 Gbps |
| TAG server | i3en.24xlarge | 96 | 768 GiB | 60 TB SSD | 100 Gbps |

TAG was run as a single native instance via `native/run.sh`. During the benchmarks, TAG CPU usage stayed under 800% and memory usage remained around 4 GB, leaving significant headroom on the server.

## Results — Dataset Fits in Memory

| Object Size | Threads | OPS | p50 (us) | p99 (us) |
|-------------|---------|---------|----------|----------|
| 1 KB | 16 | 34,117 | 380 | 1,024 |
| 1 KB | 32 | 47,743 | 484 | 2,275 |
| 1 KB | 64 | 55,231 | 744 | 4,443 |
| 100 KB | 16 | 7,906 | 1,842 | 4,015 |
| 100 KB | 32 | 8,697 | 3,389 | 9,775 |
| 100 KB | 64 | 9,726 | 4,411 | 25,999 |
| 1 MB | 16 | 2,981 | 4,891 | 8,431 |
| 1 MB | 32 | 4,816 | 6,523 | 11,223 |
| 1 MB | 64 | 6,255 | 9,655 | 19,727 |

## Key Observations

- **1 KB objects**: Over 55K ops/sec at 64 threads with sub-millisecond p50 latency.
- **100 KB objects**: Throughput reaches ~9.7K ops/sec at 64 threads (~7.8 Gbps).
- **1 MB objects**: Over 6.2K ops/sec at 64 threads (~50 Gbps), with p50 under 10 ms.
- Throughput scales with thread count across all object sizes, while the server remains well below resource limits.

## Limitations

A single go-ycsb instance does not scale well past ~20 Gbps of throughput and struggles with object sizes above 1 MB. These results represent a lower bound on TAG's actual capacity — multiple go-ycsb clients would be needed to fully saturate the server.
