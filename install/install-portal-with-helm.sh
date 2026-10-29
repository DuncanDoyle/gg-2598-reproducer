#!/bin/sh

. ./env.sh

if [ -z "$ENT_KGATEWAY_LICENSE_KEY" ]
then
   echo "Solo Enterprise for Kgateway License Key not specified. Please configure the environment variable 'ENT_KGATEWAY_LICENSE_KEY' with your Solo Enterprise for kgateway License Key."
   exit 1
fi

export PORTAL_CRDS_URL="oci://us-docker.pkg.dev/solo-public/enterprise-kgateway/charts/portal-crds"
export PORTAL_URL="oci://us-docker.pkg.dev/solo-public/enterprise-kgateway/charts/portal"

#----------------------------------------- Install Solo Enterprise for kgateway Portal -----------------------------------------

printf "\nInstall Solo Enterprise for Kgateway Portal CRDs ....\n"
helm upgrade --install portal-crds $PORTAL_CRDS_URL \
    --version $PORTAL_VERSION \
    --namespace $PORTAL_NAMESPACE \
    --create-namespace

printf "\nInstall Solo Enterprise for Kgateway Portal ...\n"
helm upgrade --install portal $PORTAL_URL \
    --version $PORTAL_VERSION \
    --namespace $PORTAL_NAMESPACE \
    --create-namespace \
    --set-string licensing.licenseKey=$ENT_KGATEWAY_LICENSE_KEY
