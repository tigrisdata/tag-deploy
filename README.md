# TAG Deploy — Deprecated

> [!WARNING]
> **This repository is deprecated and no longer maintained.**
>
> TAG (Tigris Access Gateway) has been open-sourced, and all deployment
> manifests, scripts, and documentation now live in the main repository:
> **[tigrisdata/tag](https://github.com/tigrisdata/tag)**.
>
> Please use that repository. This one is archived and read-only.

## Where everything moved

Deployment artifacts now live under [`deploy/`](https://github.com/tigrisdata/tag/tree/main/deploy) and docs under [`docs/`](https://github.com/tigrisdata/tag/tree/main/docs) in [tigrisdata/tag](https://github.com/tigrisdata/tag):

| This repo (`tag-deploy`)            | New location in `tigrisdata/tag`                          |
| ----------------------------------- | -------------------------------------------------------- |
| `kubernetes/base/`                  | [`deploy/kubernetes/base/`](https://github.com/tigrisdata/tag/tree/main/deploy/kubernetes/base) |
| `native/` (install/run/config)      | [`deploy/native/`](https://github.com/tigrisdata/tag/tree/main/deploy/native) |
| `docker/docker-compose*.yml`        | [`deploy/docker/*.release.yml`](https://github.com/tigrisdata/tag/tree/main/deploy/docker) (released-image variants) |
| `docs/deploy.md`                    | [`docs/deploy.md`](https://github.com/tigrisdata/tag/blob/main/docs/deploy.md) |
| `docs/docker.md`                    | [`docs/docker.md`](https://github.com/tigrisdata/tag/blob/main/docs/docker.md) |
| `docs/tls.md`                       | [`docs/tls.md`](https://github.com/tigrisdata/tag/blob/main/docs/tls.md) |
| `docs/benchmarks.md`                | [`docs/benchmarks.md`](https://github.com/tigrisdata/tag/blob/main/docs/benchmarks.md) |
| `docs/{configuration,security,metrics,usage,cache-control}.md` | Canonical versions in [`tigrisdata/tag/docs/`](https://github.com/tigrisdata/tag/tree/main/docs) |

## Getting started (in the new repo)

Install the latest release without cloning anything:

```bash
curl -fsSL https://tag-releases.t3.storage.dev/latest/install.sh | bash
```

- **Kubernetes** — [docs/deploy.md](https://github.com/tigrisdata/tag/blob/main/docs/deploy.md)
- **Docker** — [docs/docker.md](https://github.com/tigrisdata/tag/blob/main/docs/docker.md)
- **TLS/HTTPS** — [docs/tls.md](https://github.com/tigrisdata/tag/blob/main/docs/tls.md)
- **Configuration** — [docs/configuration.md](https://github.com/tigrisdata/tag/blob/main/docs/configuration.md)

See the [tigrisdata/tag README](https://github.com/tigrisdata/tag#readme) for everything else.
