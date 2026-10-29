# Solo Enterprise for kgateway - Portal: portalAuth returns 403 instead of 401 for a missing or invalid API key

Reproducer for [solo-io/gloo-gateway#2598](https://github.com/solo-io/gloo-gateway/issues/2598).

One Gateway serves the same httpbin backend on two hostnames, both checking an API key in the `x-api-key` header:

| Hostname | Auth | AuthConfig |
|---|---|---|
| `apikey.example.com` | Standalone ext-auth `apiKeyAuth` | [`policies/authconfig/apikey-authconfig.yaml`](policies/authconfig/apikey-authconfig.yaml) |
| `portal.example.com` | `portalAuth` in API key mode, route exposed as an `ApiProduct` | [`policies/authconfig/portalauth-apikey-authconfig.yaml`](policies/authconfig/portalauth-apikey-authconfig.yaml) |

## Versions

| Component | Version |
|---|---|
| Solo Enterprise for kgateway | 2.3.8 |
| Portal | 2.3.8 |
| kgateway OSS (base of SEFK 2.3.8) | v2.4.7 |
| Kubernetes Gateway API | v1.6.1 |
| ext-auth-service (as logged) | 0.87.1 |

Built and verified on a kind cluster on 2026-10-29. The versions are set in [`install/env.sh`](install/env.sh).

## Steps to reproduce

Set `ENT_KGATEWAY_LICENSE_KEY`, then:

```sh
cd install
./install-ent-kgateway-with-helm.sh
./install-portal-with-helm.sh
./setup.sh
cd ..
./test.sh
```

`test.sh` sends requests to the Gateway's status address. On a cluster without a LoadBalancer, port-forward and pass the address:

```sh
kubectl -n ingress-gw port-forward deploy/gw 8080:80 &
GW_ADDRESS=localhost:8080 ./test.sh
```

## Expected behaviour

A missing or invalid API key returns `401 Unauthorized` with `WWW-Authenticate: API key is missing or invalid` on both hostnames.

## Actual behaviour

```
== Missing API key
  apikey.example.com                 HTTP/1.1 401 Unauthorized  www-authenticate: API key is missing or invalid
  portal.example.com                 HTTP/1.1 403 Forbidden  (no WWW-Authenticate header)

== Invalid API key
  apikey.example.com                 HTTP/1.1 401 Unauthorized  www-authenticate: API key is missing or invalid
  portal.example.com                 HTTP/1.1 403 Forbidden  (no WWW-Authenticate header)

== Valid API key (standalone only; shows the apiKeyAuth route is set up correctly)
  apikey.example.com                 HTTP/1.1 200 OK  (no WWW-Authenticate header)

== portalAuth denial reasons logged by ext-auth (last 2)
  request is configured to use api key auth but does not have api key
  credential is not allowed to access api product: httpbin
```

The ext-auth log confirms that `portalAuth` makes both denials, so the 403 is not a misconfiguration. An invalid key logs the same "not allowed to access api product" error as a valid key without a subscription. ext-auth therefore cannot return 401 for one and 403 for the other until the Portal server says why it denied the key.

## Root cause

Every `portalAuth` denial in [`pkg/config/portalauth/portal_auth_service.go`](https://github.com/solo-io/ext-auth-service/blob/e0cdf61e12b7a2f704edbe7012556eae1b0addf0/pkg/config/portalauth/portal_auth_service.go#L240-L250) returns `api.UnauthorizedResponse()`. That response sets no HTTP status, so Envoy's `ext_authz` filter falls back to 403. Standalone API key auth sets `StatusCode_Unauthorized` and the `WWW-Authenticate` header in [`pkg/config/apikeys/response.go`](https://github.com/solo-io/ext-auth-service/blob/e0cdf61e12b7a2f704edbe7012556eae1b0addf0/pkg/config/apikeys/response.go#L140-L146).
