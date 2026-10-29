#!/bin/sh

cd ..

# Gateway
kubectl create namespace ingress-gw --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f gateways/gw-parameters.yaml
kubectl apply -f gateways/gw.yaml

# The gateway only accepts routes from namespaces with this label.
kubectl create namespace httpbin --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespaces httpbin --overwrite shared-gateway-access="true"

printf "\nDeploy HTTPBin application ...\n"
kubectl apply -f apis/httpbin.yaml

printf "\nDeploy HTTPRoutes ...\n"
kubectl apply -f routes/apikey-example-com-httproute.yaml
kubectl apply -f routes/portal-example-com-httproute.yaml

printf "\nDeploy Portal and the HTTPBin ApiProduct ...\n"
kubectl apply -f apiproducts/httpbin-apiproduct.yaml
kubectl apply -f portal/portal.yaml

printf "\nDeploy API key Secret, AuthConfigs and EnterpriseKgatewayTrafficPolicies ...\n"
kubectl apply -f api-keys/httpbin-apikey-secret.yaml
kubectl apply -f policies/authconfig/apikey-authconfig.yaml
kubectl apply -f policies/authconfig/portalauth-apikey-authconfig.yaml
kubectl apply -f policies/extauth-httproute-policies.yaml
