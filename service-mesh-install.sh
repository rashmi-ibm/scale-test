#!/bin/bash

# Fail on error
set -e

# Install subscriptions
oc apply -f service-mesh-subs.yaml

while :
do
  INCOMPLETE_OPERATORS=$(oc get subs -o json -n openshift-operators | jq -r '.items[] | select (.status.state!="AtLatestKnown") | .metadata.name')
  if [ -z "$INCOMPLETE_OPERATORS" ]; then
    break;
  fi
  echo -e "Incomplete operators:\n$INCOMPLETE_OPERATORS"
  UNAPPROVED_INSTALLPLANS=$(oc get installplan -n openshift-operators -o json | jq -r '.items[] | select(.spec.approved==false) | .metadata.name')
  echo -e "Unapproved installplans:\n$UNAPPROVED_INSTALLPLANS"
  if [ -n "$UNAPPROVED_INSTALLPLANS" ]; then
    for INSTALLPLAN in "$UNAPPROVED_INSTALLPLANS"
    do
      echo "Patch installplan '$INSTALLPLAN'"
      oc patch installplan -n openshift-operators $INSTALLPLAN -p '{"spec":{"approved":true}}' --type=merge
    done
  fi
done

VERSION=${VERSION:-"2.0"}
if [ "$VERSION" == "2.0" ]; then
   SMCP=smcp_v2.yaml
   # Istiod, prometheus and ingress gateway
   EXPECTED_PODS=3
else
   SMCP=smcp.yaml
   EXPECTED_PODS=7
fi

while :
do
  ADMISSION_CONTROLLERS=$(oc get ep -n openshift-operators maistra-admission-controller -o json | jq '.subsets[0].addresses | length')
  if [ $ADMISSION_CONTROLLERS -eq "1" ]; then
    echo "Admission controller is up."
    break;
  fi
  echo "Waiting for admission controller to boot, ready: $ADMISSION_CONTROLLERS"
  sleep 5
done;

# Install control-plane
oc new-project mesh-control-plane || true # don't fail if it exists
while ! oc apply -f $SMCP ; do
  echo "The operator pod is probably not accepting connections yet..."
  sleep 5;
done;

# Create mesh-scale namespace so we can register a member roll
oc new-project mesh-scale || true # don't fail if it exists
oc apply -f smmr.yaml

# Wait until operator creates the deployment
while ! oc get deployment istio-ingressgateway -n mesh-control-plane 2> /dev/null; do
  echo "Ingress gateway is not up yet"
  sleep 1;
done;

# Make sure there's only one gateway (otherwise the loop below gets stuck)
oc scale deployment istio-ingressgateway -n mesh-control-plane --replicas=1

# Wait until everyone boots up
while :
do
  PODS_UP=$(oc get po -n mesh-control-plane --field-selector 'status.phase=Running' -o json | jq '.items | length')
  if [ $PODS_UP -eq $EXPECTED_PODS ]; then
    echo "All control-plane pods are up and running"
    break;
  fi
  echo "Waiting for mesh-control-plane, $PODS_UP/$EXPECTED_PODS pods up"
  sleep 5
done