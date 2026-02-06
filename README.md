# TAG Deployment Guide

This guide covers deploying TAG in various environments.

## Prerequisites

- Access to Tigris storage with API credentials

## Docker

### Quick Start

```bash
# Single node
cd docker
docker-compose up -d

# Cluster mode (3 TAG nodes with embedded cache)
docker-compose -f docker-compose-cluster.yml up -d
```

### Environment Variables

Create a `.env` file in the `docker/` directory:

```bash
# Required
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key

# Optional
TAG_LOG_LEVEL=info
```

### Single Node Setup

```bash
# Start service
docker-compose -f docker/docker-compose.yml up -d

# View logs
docker-compose -f docker/docker-compose.yml logs -f tag

# Stop service
docker-compose -f docker/docker-compose.yml down
```

### Cluster Setup

```bash
# Start 3 TAG nodes with embedded cache cluster
docker-compose -f docker/docker-compose-cluster.yml up -d

# TAG endpoints are available at:
# - http://localhost:8081 (tag-1)
# - http://localhost:8082 (tag-2)
# - http://localhost:8083 (tag-3)

# Stop cluster
docker-compose -f docker/docker-compose-cluster.yml down -v
```

### Test

```bash
# Test with curl
curl -X GET http://localhost:8080/your-bucket/your-key \
  -H "Authorization: AWS4-HMAC-SHA256 ..."

# Test with AWS CLI
aws s3 cp s3://your-bucket/your-key ./local-file \
  --endpoint-url http://localhost:8080
```

## Kubernetes

### Prerequisites

1. A running Kubernetes cluster
2. kubectl configured to access the cluster

### Deploy

```bash
# Create namespace (optional)
kubectl create namespace tag

# Create credentials secret
kubectl create secret generic tag-credentials \
  --namespace tag \
  --from-literal=AWS_ACCESS_KEY_ID=your_key \
  --from-literal=AWS_SECRET_ACCESS_KEY=your_secret

# Apply with kustomize
kubectl apply -k kubernetes/base/ -n tag
```

### Kubernetes Manifests

The `kubernetes/base/` directory uses Kustomize format:

| File | Description |
|------|-------------|
| `kustomization.yaml` | Kustomize configuration |
| `statefulset.yaml` | TAG StatefulSet with embedded cache |
| `service.yaml` | LoadBalancer Service for external access |
| `service-headless.yaml` | Headless Service for cluster discovery |
| `hpa.yaml` | Horizontal Pod Autoscaler |

## Native

Run TAG as a native process using pre-built binaries with embedded cache.

### Quick Start

```bash
# Set credentials
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key

# Start service
./native/run.sh start

# Check status
./native/run.sh status

# Stop service
./native/run.sh stop
```

### Commands

| Command | Description |
|---------|-------------|
| `start` | Download binary (if needed) and start TAG |
| `stop` | Stop service |
| `stop --clean` | Stop service and remove all data |
| `status` | Show running status and health |
| `logs [lines]` | Show logs (default: 50 lines) |
| `help` | Show usage information |

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AWS_ACCESS_KEY_ID` | (required) | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | (required) | AWS secret key |
| `TAG_VERSION` | `v1.5.1` | TAG version to download |
| `TAG_LOG_LEVEL` | `info` | Log level: debug, info, warn, error |
| `TAG_PORT` | `8080` | TAG HTTP port |
| `TAG_CACHE_MAX_DISK_USAGE` | `107374182400` | Max cache disk usage in bytes (100GB) |
| `BIN_DIR` | `native/.bin` | Binary download directory |
| `DATA_DIR` | `/tmp/native-data` | Data directory for logs and cache |

### Examples

```bash
# Start with debug logging
TAG_LOG_LEVEL=debug ./native/run.sh start

# Use specific version
TAG_VERSION=v1.5.1 ./native/run.sh start

# View logs
./native/run.sh logs 100

# Stop and clean all data
./native/run.sh stop --clean
```

## Cache Configuration

TAG uses an embedded distributed cache. Each TAG instance has its own local RocksDB-based cache storage.

### Single Node

For single-node deployments, configure:

| Variable | Default | Description |
|----------|---------|-------------|
| `TAG_CACHE_NODE_ID` | auto | Unique node identifier |
| `TAG_CACHE_DISK_PATH` | `/data/cache` | Cache data directory |
| `TAG_CACHE_MAX_DISK_USAGE` | `0` (unlimited) | Max disk usage in bytes |

### Cluster Mode

For clustered deployments, nodes communicate via:
- **Port 7000**: Gossip port for cluster discovery
- **Port 9000**: Port for cluster internal communication

Additional cluster configuration:

| Variable | Default | Description |
|----------|---------|-------------|
| `TAG_CACHE_CLUSTER_ADDR` | `:7000` | Gossip protocol address |
| `TAG_CACHE_GRPC_ADDR` | `:9000` | Cluster internal communication address |
| `TAG_CACHE_ADVERTISE_ADDR` | (auto) | Address advertised to peers |
| `TAG_CACHE_SEED_NODES` | (none) | Cluster discovery nodes |

## Production Considerations

### High Availability

- Deploy multiple TAG replicas using the StatefulSet
- Each TAG node has its own embedded cache storage
- Use Kubernetes pod anti-affinity rules for node distribution
- Configure health checks for automatic recovery

### Scaling

**Horizontal Scaling:**
- TAG nodes form a distributed cache cluster
- Adding nodes automatically rebalances cache keys
- HPA can scale based on CPU/memory metrics
- Note: Scaling down may temporarily reduce cache hit ratio

**Vertical Scaling:**
- Increase memory for high concurrent connection count
- Increase CPU for high request throughput
- SSD storage is required for cache performance

### Health Checks

TAG exposes a health endpoint:

```
GET /health
```

Returns `200 OK` when healthy.

### Monitoring

1. Expose `/metrics` endpoint for Prometheus scraping
2. Set up alerts for:
   - High error rate (`tag_requests_total{status="error"}`)
   - Low cache hit ratio (`tag_cache_hits_total / (tag_cache_hits_total + tag_cache_misses_total)`)
   - High upstream latency (`tag_upstream_request_duration_seconds`)

## Benchmarks

See [BENCHMARKS.md](BENCHMARKS.md) for performance results from go-ycsb testing on EC2.

## Troubleshooting

### Common Issues

**No cache hits:**
- Verify TAG is running with embedded cache enabled
- Check TAG logs for cache initialization errors
- Ensure disk path is writable

**Authentication failures:**
- Verify credentials are set correctly
- Check clock sync between client and TAG
- Review signature calculation logs at debug level

**High latency:**
- Check upstream endpoint latency
- Monitor cache hit ratio
- Review disk I/O performance

### Debug Mode

Enable debug logging for troubleshooting:

```bash
TAG_LOG_LEVEL=debug ./tag
```

Or in Kubernetes:

```yaml
env:
  - name: TAG_LOG_LEVEL
    value: "debug"
```
