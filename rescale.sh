#!/bin/bash

CONTROL_PLANE=$1
ROUTERS=$2
GATEWAYS=$3

oc scale ingresscontrollers.operator.openshift.io default -n openshift-ingress-operator --replicas=$ROUTERS
oc scale -n $CONTROL_PLANE deployment istio-ingressgateway --replicas=$GATEWAYS

for attempt in $(seq 1 60); do
    CURR_RT=$(oc get po -n openshift-ingress -o json | jq '.items | length')
    CURR_GW=$(oc get po -n $CONTROL_PLANE -l app=istio-ingressgateway -o json | jq '.items | length')
    echo "Mesh has $CURR_RT routers and $CURR_GW gateways."
    if [ "$CURR_GW" = "$GATEWAYS" -a "$CURR_RT" = "$ROUTERS" ]; then
        break;
    fi;
    echo "Attempt $attempt/60"
    if [ $attempt -eq 60 ]; then
        echo "Scaling timed out."
        exit 1
    fi;
    sleep 3
done
