# Configuration Reference

TAG is configured through environment variables or a YAML configuration file. Environment variables take precedence over config file values.

## Credentials

TAG requires Tigris credentials to forward requests to the upstream Tigris storage.

| Variable                | Required | Description       |
| ----------------------- | -------- | ----------------- |
| `AWS_ACCESS_KEY_ID`     | Yes      | Tigris access key |
| `AWS_SECRET_ACCESS_KEY` | Yes      | Tigris secret key |

`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` are TAG's own Tigris credentials with read-only access to all buckets accessed through TAG (required). Clients use their own credentials directly.

## Server

| Variable                      | Default | Description                                 |
| ----------------------------- | ------- | ------------------------------------------- |
| `TAG_PORT`                    | `8080`  | HTTP listen port                            |
| `TAG_LOG_LEVEL`               | `info`  | Log level: `debug`, `info`, `warn`, `error` |
| `TAG_PPROF_ENABLED`           | `false` | Enable pprof profiling endpoint             |
| `TAG_MAX_IDLE_CONNS_PER_HOST` | `100`   | Max idle connections per upstream host      |

## TLS

See [TLS/HTTPS](tls.md) for full details.

| Variable            | Default | Description                  |
| ------------------- | ------- | ---------------------------- |
| `TAG_TLS_CERT_FILE` | (none)  | Path to TLS certificate file |
| `TAG_TLS_KEY_FILE`  | (none)  | Path to TLS private key file |

## Cache

TAG uses an embedded distributed cache backed by RocksDB. Each TAG instance maintains its own local cache.

### Single Node

| Variable                   | Default         | Description             |
| -------------------------- | --------------- | ----------------------- |
| `TAG_CACHE_NODE_ID`        | (auto)          | Unique node identifier  |
| `TAG_CACHE_DISK_PATH`      | `/data/cache`   | Cache data directory    |
| `TAG_CACHE_MAX_DISK_USAGE` | `0` (unlimited) | Max disk usage in bytes |

### Cluster Mode

In cluster mode, TAG nodes discover each other via gossip and communicate over gRPC.

| Variable                   | Default | Description                                                                                                         |
| -------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------- |
| `TAG_CACHE_CLUSTER_ADDR`   | `:7000` | Gossip protocol listen address. The native runner defaults to `:17000` to avoid conflict with macOS Control Center. |
| `TAG_CACHE_GRPC_ADDR`      | `:9000` | gRPC listen address for inter-node communication                                                                    |
| `TAG_CACHE_ADVERTISE_ADDR` | (auto)  | Address advertised to peers for gRPC                                                                                |
| `TAG_CACHE_SEED_NODES`     | (none)  | Comma-separated list of seed nodes for cluster discovery                                                            |

#### Ports

| Port | Protocol | Purpose                                 |
| ---- | -------- | --------------------------------------- |
| 7000 | TCP      | Gossip protocol for cluster discovery   |
| 8080 | TCP      | HTTP API (S3-compatible)                |
| 9000 | TCP      | gRPC for inter-node cache communication |

## Configuration File

TAG can also be configured via a YAML file. Pass the config file path as a command-line argument:

```bash
./tag --config /etc/tag/config.yaml
```

Example configuration:

```yaml
server:
  port: 8080
  log_level: info
  tls_cert_file: /etc/tag/tls/cert.pem
  tls_key_file: /etc/tag/tls/key.pem

cache:
  node_id: tag-1
  disk_path: /data/cache
  max_disk_usage: 429496729600
  cluster_addr: ":7000"
  grpc_addr: ":9000"
  seed_nodes: "tag-headless:7000"
```

Environment variables override any values set in the config file.
