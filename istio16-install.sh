#!/bin/bash

# Check that service mesh is gone
SMNS=$(oc get namespace mesh-control-plane mesh-scale -o name 2> /dev/null)
if [ -n "$SMNS" ]; then
    echo "Service Mesh is installed, please remove";
    exit 1;
fi;

# Fail on error
set -e -x

# Install control plane
oc adm policy add-scc-to-group anyuid system:serviceaccounts:istio-system

if [ ! -f ./istioctl ]; then
    wget https://github.com/istio/istio/releases/download/1.6.13/istioctl-1.6.13-linux-amd64.tar.gz
    tar xzf istioctl-1.6.13-linux-amd64.tar.gz
fi
./istioctl operator init

# Install control-plane
oc new-project istio-system || true # don't fail if it exists
oc delete istiooperators.install.istio.io basic-install || true # Update sometimes fails due to resource version
sleep 5 # Sometimes there's a lag for delting
oc apply -f istio16.yaml

# Wait until the deployment appears
while :
do
  DEPLOYMENTS=$(oc get deployment -l istio=ingressgateway -o json | jq '.items | length')
  if [ $DEPLOYMENTS -eq 1 ]; then
     echo "Deployment was created"
     break
  fi
  echo "Waiting for ingress gateway deployment..."
  sleep 5
done

# Make sure there's only one gateway (otherwise the loop below gets stuck)
oc scale deployment istio-ingressgateway -n istio-system --replicas=1
# Wait until everyone boots up
EXPECTED_PODS=3
while :
do
  PODS_UP=$(oc get po -n istio-system --field-selector 'status.phase=Running' -o json | jq '.items | length')
  if [ $PODS_UP -eq $EXPECTED_PODS ]; then
    echo "All control-plane pods are up and running"
    break
  fi
  echo "Waiting for istio-system, $PODS_UP/$EXPECTED_PODS pods up"
  sleep 5
done

# Create workload namespace
if ! oc get namespace istio-scale; then
    oc new-project istio-scale
    oc label namespace istio-scale istio-injection=enabled
    oc create -n istio-scale -f istio-net-attach-def.yaml
    oc adm policy add-scc-to-group anyuid system:serviceaccounts:istio-scale
fi
