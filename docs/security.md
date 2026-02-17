# Security & Access Control

This document describes TAG's authentication, authorization, and security architecture.

## Authentication Modes

TAG supports two authentication modes, controlled by the `transparent_proxy` configuration setting.

### Transparent Proxy (Default)

Clients sign requests with their own Tigris credentials. TAG forwards the request as-is, preserving the original `Authorization` header, and adds additional proxy headers to identify itself to Tigris.

Tigris independently validates both the client's SigV4 signature and TAG's proxy signature. TAG's access key must belong to the same Tigris organization as the client's access key.

## Local Authentication

TAG implements local SigV4 validation to serve cache hits without contacting Tigris on every request.

### How It Works

**First request (key learning):**

```text
Client                     TAG                          Tigris
  │                         │                             │
  │  GET /bucket/key        │                             │
  │  Authorization: ...     │                             │
  │────────────────────────▶│                             │
  │                         │  Forward + proxy headers    │
  │                         │────────────────────────────▶│
  │                         │◀────────────────────────────│
  │                         │  200 OK                     │
  │                         │  X-Tigris-Proxy-Signing-Keys│
  │                         │                             │
  │                         │  (unwrap & store keys)      │
  │                         │  (grant authz cache entry)  │
  │◀────────────────────────│                             │
  │  200 OK (key header     │                             │
  │  stripped from response)│                             │
```

**Subsequent requests (local validation):**

```text
Client                     TAG                          Tigris
  │                         │                             │
  │  GET /bucket/key        │                             │
  │  Authorization: ...     │                             │
  │────────────────────────▶│                             │
  │                         │  Validate SigV4 locally     │
  │                         │  Check authz cache          │
  │                         │  → AuthValidated            │
  │                         │                             │
  │                         │  Serve from cache           │
  │◀────────────────────────│                             │
  │  200 OK                 │                             │
  │  X-Cache: HIT           │                             │
```

## Access Control Flow

```text
Request arrives at TAG
    │
    ├─ No Authorization header (anonymous)
    │   └─ Forward to Tigris → Tigris decides (e.g., public bucket access)
    │
    ├─ Malformed Authorization header
    │   └─ Reject with 4xx error
    │
    ├─ Access key not known to TAG (first request or unknown key)
    │   └─ Forward to Tigris → learn keys on successful response
    │
    ├─ SigV4 signature mismatch
    │   └─ Forward to Tigris → re-learn keys if signature was stale
    │
    ├─ AuthzCache miss or expired
    │   └─ Forward to Tigris → re-authorize on successful response
    │
    └─ Valid signature + valid authz cache entry
        └─ AuthValidated → serve from cache if available
```

## Authorization Lifecycle

Authorization decisions are cached per `(accessKey, bucket)` pair:

| Event                                | Action                                    |
| ------------------------------------ | ----------------------------------------- |
| Tigris returns 2xx with signing keys | `AuthzCache.Grant(accessKey, bucket)`     |
| Tigris returns 403                   | `AuthzCache.Revoke(accessKey, bucket)`    |
| TTL expires (10 min default)         | Entry removed, next request re-authorizes |

Authorization is strictly per-bucket. A client may have access to some buckets but not others, and TAG enforces this at the cache level.

## Proxy Header Security

### Preventing Client Injection

TAG overwrites any client-supplied proxy header values with TAG's own computed values.

### Proxy Signature Computation

TAG computes the proxy signature using its own secret key. Only TAG (and Tigris, which knows TAG's key) can produce a valid proxy signature.

## Endpoint Validation

TAG validates the upstream endpoint at startup to prevent misconfiguration and SSRF attacks.

**Allowed hosts:**

| Pattern         | Example                          | Use Case                  |
| --------------- | -------------------------------- | ------------------------- |
| `localhost`     | `http://localhost:8080`          | Development and testing   |
| `*.tigris.dev`  | `https://fly.storage.tigris.dev` | Tigris production domains |
| `*.storage.dev` | `https://t3.storage.dev`         | Tigris storage domains    |

Any other endpoint causes a fatal startup error.

## Credential Requirements

TAG requires its own Tigris credentials via environment variables:

```bash
export AWS_ACCESS_KEY_ID=<TAGs access key>
export AWS_SECRET_ACCESS_KEY=<TAGs secret key>
```

These credentials must have **read-only access** to all buckets accessed through TAG. This is required for:

- Signing proxy headers (transparent mode)
- Background cache fetches (e.g., fetching full objects after a range request cache miss)

TAG's access key must belong to the same Tigris organization as client access keys. Clients use their own credentials directly — TAG does not need or store client secret keys.

## Error Mapping

| Auth Error         | S3 Error Code         | HTTP Status | Action            |
| ------------------ | --------------------- | ----------- | ----------------- |
| Signature mismatch | SignatureDoesNotMatch | 403         | Forward to Tigris |
| Unknown access key | InvalidAccessKeyId    | 403         | Forward to Tigris |
| Expired request    | RequestTimeTooSkewed  | 403         | Forward to Tigris |
| Malformed auth     | MalformedAuth         | 400         | Reject at TAG     |
| Missing auth       | (none)                | (none)      | Forward to Tigris |
