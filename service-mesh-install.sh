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

# Install control-plane
oc new-project mesh-control-plane || true # don't fail if it exists
oc apply -f smcp.yaml

# Create mesh-scale namespace so we can register a member roll
oc new-project mesh-scale || true # don't fail if it exists
oc apply -f smmr.yaml

# Make sure there's only one gateway (otherwise the loop below gets stuck)
oc scale deployment istio-ingressgateway -n mesh-control-plane --replicas=1

# Wait until everyone boots up
while :
do
  PODS_UP=$(oc get po -n mesh-control-plane --field-selector 'status.phase=Running' -o json | jq '.items | length')
  if [ $PODS_UP -eq 7 ]; then
    echo "All control-plane pods are up and running"
    break;
  fi
  echo "Waiting for istio-system, $PODS_UP/7 pods up"
  sleep 5
done