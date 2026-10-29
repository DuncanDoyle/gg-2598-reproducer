#!/bin/sh
# Sends the same requests to two routes on the same gateway and backend:
#   apikey.example.com -> standalone apiKeyAuth AuthConfig
#   portal.example.com -> portalAuth AuthConfig in apiKey mode
#
# Expected: a missing or invalid key returns 401 with
#   "WWW-Authenticate: API key is missing or invalid" on both routes.
# Actual: apikey.example.com returns 401 with that header;
#   portal.example.com returns 403 with no WWW-Authenticate header.

# Gateway address. Defaults to the Gateway status address; override for a port-forward,
# e.g. GW_ADDRESS=localhost:8080 after "kubectl -n ingress-gw port-forward deploy/gw 8080:80".
GW_ADDRESS=${GW_ADDRESS:-$(kubectl get gateway gw -n ingress-gw -o jsonpath='{.status.addresses[0].value}')}

# Prints the status line and the WWW-Authenticate header (if any) of one request.
request() {
  host=$1; shift
  out=$(curl -s -o /dev/null -D - -H "Host: $host" "$@" "http://$GW_ADDRESS/get")
  status=$(printf '%s' "$out" | head -1 | tr -d '\r')
  www=$(printf '%s' "$out" | grep -i '^www-authenticate:' | tr -d '\r')
  printf '  %-34s %s  %s\n' "$host" "$status" "${www:-(no WWW-Authenticate header)}"
}

printf "\n== Missing API key\n"
request apikey.example.com
request portal.example.com

printf "\n== Invalid API key\n"
request apikey.example.com -H "x-api-key: invalid-api-key"
request portal.example.com -H "x-api-key: invalid-api-key"

printf "\n== Valid API key (standalone only; shows the apiKeyAuth route is set up correctly)\n"
request apikey.example.com -H "x-api-key: valid-api-key"

# An invalid key and a valid-but-unsubscribed key both log "credential is not allowed to
# access api product", so ext-auth cannot tell them apart without more data from the Portal server.
printf "\n== portalAuth denial reasons logged by ext-auth (last 2)\n"
kubectl logs -n kgateway-system deploy/ext-auth-service-enterprise-kgateway --since=1m 2>/dev/null \
  | grep '"authService":"portalAuth"' | sed -E 's/.*"error":"([^"]*)".*/  \1/' | tail -2
