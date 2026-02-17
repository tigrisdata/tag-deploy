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
| Linux    | amd64                 | [tag-linux-amd64](https://tag-releases.t3.storage.dev/v1.6.0/tag-linux-amd64)   |
| Linux    | arm64                 | [tag-linux-arm64](https://tag-releases.t3.storage.dev/v1.6.0/tag-linux-arm64)   |
| macOS    | arm64 (Apple Silicon) | [tag-darwin-arm64](https://tag-releases.t3.storage.dev/v1.6.0/tag-darwin-arm64) |

To download a specific version, replace `v1.6.0` with the desired version tag:

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
  tigrisdata/tag:v1.6.0
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

## Documentation

- [Configuration Reference](docs/configuration.md) - All environment variables, config file format, cache settings
- [Docker](docs/docker.md) - Docker single node and cluster deployment
- [Kubernetes Deployment](docs/deploy.md) - Production deployment, scaling, monitoring, troubleshooting
- [TLS/HTTPS](docs/tls.md) - Enable encrypted connections
- [Benchmarks](docs/benchmarks.md) - Performance results on EC2
