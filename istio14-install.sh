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
    wget https://github.com/istio/istio/releases/download/1.4.10/istioctl-1.4.10-linux.tar.gz
    tar xzf istioctl-1.4.10-linux.tar.gz
fi
./istioctl manifest apply -f istio14.yaml

# Make sure there's only one gateway (otherwise the loop below gets stuck)
oc scale deployment istio-ingressgateway -n istio-system --replicas=1
# Wait until everyone boots up
while :
do
  PODS_UP=$(oc get po -n istio-system --field-selector 'status.phase=Running' -o json | jq '.items | length')
  if [ $PODS_UP -eq 6 ]; then
    echo "All control-plane pods are up and running"
    break;
  fi
  echo "Waiting for istio-system, $PODS_UP/6 pods up"
  sleep 5
done

# Create workload namespace
if ! oc get namespace istio-scale; then
    oc new-project istio-scale
    oc label namespace istio-scale istio-injection=enabled
    oc create -n istio-scale -f istio-net-attach-def.yaml
fi