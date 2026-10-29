#!/bin/sh

# SEFK 2.3.8 is built on kgateway OSS v2.4.7, which is built against Gateway API v1.6.1.
export ENT_KGATEWAY_VERSION="2.3.8"
export PORTAL_VERSION="2.3.8"
export K8S_GW_API_VERSION="v1.6.1"
export ENT_KGATEWAY_HELM_VALUES_FILE="ent-kgateway-helm-values.yaml"

export ENT_KGATEWAY_SYSTEM_NAMESPACE="kgateway-system"
export PORTAL_NAMESPACE="kgateway-system"
