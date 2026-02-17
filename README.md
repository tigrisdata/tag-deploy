# TAG

TAG is a high-performance S3-compatible caching proxy for [Tigris](https://www.tigrisdata.com/) object storage. It provides transparent caching with request coalescing to reduce upstream load and improve latency for frequently accessed objects.

## Features

- **S3-Compatible API** - Supports all S3 API endpoints supported by Tigris
- **Transparent Proxy Mode** - Forwards client requests as-is with proxy headers, preserving original signatures (enabled by default)
- **Embedded Cache** - High-performance RocksDB-based cache with automatic cluster discovery
- **Request Coalescing** - Streaming broadcast pattern reduces duplicate upstream requests under concurrent load
- **Range Request Caching** - Background fetch of full objects on range cache miss for optimal ML training workloads
- **Conditional Requests** - Supports If-None-Match and If-Modified-Since for efficient cache validation
- **AWS SigV4 Authentication** - Full AWS Signature Version 4 validation and re-signing
- **Prometheus Metrics** - Comprehensive metrics for monitoring cache efficiency and performance
- **Kubernetes Ready** - Includes deployment manifests for production use

## Prerequisites

`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` - TAG's own Tigris credentials with read-only access to all buckets accessed through TAG (required). Clients use their own credentials directly.

## Installation

TAG can be installed in one of three ways:

### Installation Script

```bash
curl -sSL https://raw.githubusercontent.com/tigrisdata/tag-deploy/main/native/install.sh | bash
```

### Binaries

The latest TAG binaries:

| Platform | Architecture          | Download                                                                        |
| -------- | --------------------- | ------------------------------------------------------------------------------- |
| Linux    | amd64                 | [tag-linux-amd64](https://tag-releases.t3.storage.dev/v1.7.0/tag-linux-amd64)   |
| Linux    | arm64                 | [tag-linux-arm64](https://tag-releases.t3.storage.dev/v1.7.0/tag-linux-arm64)   |
| macOS    | arm64 (Apple Silicon) | [tag-darwin-arm64](https://tag-releases.t3.storage.dev/v1.7.0/tag-darwin-arm64) |

To download a specific version, replace `v1.7.0` with the desired version tag:

```text
https://tag-releases.t3.storage.dev/$VERSION/tag-$OS-$ARCH
```

### Docker

TAG is available as a Docker image on Docker Hub:

```bash
docker run \
  --name tag \
  -p 8080:8080 \
  -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
  -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
  -e TAG_CACHE_NODE_ID=tag-standalone \
  -e TAG_CACHE_DISK_PATH=/data/cache \
  -v /tmp/tag:/data/cache \
  tigrisdata/tag:v1.7.0
```

## Run Locally

You can run TAG locally as a standalone binary or via Docker.

### Standalone Binary

Once you have installed TAG and it is in your `PATH`, set the required environment variables and start the server:

```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key

tag
```

TAG will be available at `http://localhost:8080`.

### Docker container

```bash
# Create docker/.env with credentials
cat > docker/.env <<EOF
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
EOF

# Single node
cd docker && docker-compose up -d
```

TAG will be available at `http://localhost:8080`. See [Docker](docs/docker.md) for cluster mode and detailed options.

### Test

```bash
curl http://localhost:8080/health

aws s3 cp s3://your-bucket/your-key ./local-file \
  --endpoint-url http://localhost:8080
```

## Deploy

For Kubernetes deployment, TAG runs as a StatefulSet with an embedded distributed cache cluster.

```bash
kubectl create namespace tag

kubectl create secret generic tag-credentials \
  --namespace tag \
  --from-literal=AWS_ACCESS_KEY_ID=your_access_key \
  --from-literal=AWS_SECRET_ACCESS_KEY=your_secret_key

kubectl apply -k kubernetes/base/ -n tag
```

See [Kubernetes Deployment](docs/deploy.md) for production configuration, scaling, monitoring, and troubleshooting.

## Configuration

| Variable                   | Default        | Description                                 |
| -------------------------- | -------------- | ------------------------------------------- |
| `AWS_ACCESS_KEY_ID`        | (required)     | Tigris access key                           |
| `AWS_SECRET_ACCESS_KEY`    | (required)     | Tigris secret key                           |
| `TAG_LOG_LEVEL`            | `info`         | Log level: `debug`, `info`, `warn`, `error` |
| `TAG_PORT`                 | `8080`         | HTTP listen port                            |
| `TAG_CACHE_MAX_DISK_USAGE` | `429496729600` | Max cache disk usage in bytes (400 GiB)     |

See the full [Configuration Reference](docs/configuration.md) for all options including cache cluster settings and config file format.

To enable TLS/HTTPS, see [TLS/HTTPS](docs/tls.md).

## Architecture

```text
┌─────────────┐     ┌─────────────────────────────┐     ┌─────────────┐
│   Client    │────▶│           TAG               │────▶│   Tigris    │
│  (S3 SDK)   │◀────│  ┌─────────────────────┐    │◀────│   Storage   │
└─────────────┘     │  │  Embedded Cache     │    │     └─────────────┘
                    │  │  (RocksDB + Gossip) │    │
                    │  └─────────────────────┘    │
                    └─────────────────────────────┘
```

### Request Flow

1. **Cache Check**: TAG first checks if the object exists in its embedded cache
2. **Cache Hit**: Returns cached object with `X-Cache: HIT` header
3. **Cache Miss**: Forwards request to upstream Tigris, caches response, returns with `X-Cache: MISS`

## Metrics

TAG exposes Prometheus metrics at `/metrics` including request counts, latencies, cache hit/miss rates, and broadcast statistics.

See [docs/metrics.md](docs/metrics.md) for complete metrics reference.

## Security

TAG supports transparent proxy mode with local SigV4 validation and per-bucket authorization caching.

See [docs/security.md](docs/security.md) for authentication, access control, and security architecture.

## API Reference

TAG supports all S3 API endpoints supported by Tigris, including bucket operations, object operations, multipart uploads, and more. See the [Tigris S3 API documentation](https://www.tigrisdata.com/docs/api/s3/) for the complete list of supported operations.

### S3 Addressing Style

TAG supports **path-style** S3 access only. Virtual-hosted style requests are not supported.

| Style          | URL Format                         | Supported |
| -------------- | ---------------------------------- | --------- |
| Path-style     | `http://localhost:8080/bucket/key` | Yes       |
| Virtual-hosted | `http://bucket.localhost:8080/key` | No        |

When configuring S3 clients, ensure path-style addressing is enabled. See [docs/usage.md](docs/usage.md) for SDK-specific configuration.

### Response Headers

| Header    | Description                                          |
| --------- | ---------------------------------------------------- |
| `X-Cache` | Cache status: `HIT`, `MISS`, `BYPASS`, or `DISABLED` |

### Cache Behavior

- Objects larger than `size_threshold` are not cached
- Objects with `Cache-Control: no-store` or `private` are not cached
- Range requests trigger background fetch of full object (if within threshold)
- PUT/DELETE operations invalidate the cache entry

See [docs/usage.md](docs/usage.md) for examples using AWS CLI and Python boto3.

## Documentation

- [Configuration Reference](docs/configuration.md) - All environment variables, config file format, cache settings
- [Docker](docs/docker.md) - Docker single node and cluster deployment
- [Kubernetes Deployment](docs/deploy.md) - Production deployment, scaling, monitoring, troubleshooting
- [TLS/HTTPS](docs/tls.md) - Enable encrypted connections
- [Metrics](docs/metrics.md) - Prometheus metrics reference
- [Security](docs/security.md) - Authentication, authorization, and security architecture
- [Usage](docs/usage.md) - Examples using AWS CLI and Python boto3
- [Benchmarks](docs/benchmarks.md) - Performance results on EC2
