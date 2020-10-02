#!/bin/bash

CONTROL_PLANE=$1
GATEWAYS=$2

oc scale -n $CONTROL_PLANE deployment istio-ingressgateway --replicas=$GATEWAYS
for attempt in $(seq 1 60); do
    CURR_GW=$(oc get po -n $CONTROL_PLANE -l app=istio-ingressgateway -o json | jq '.items | length')
    if [ "$CURR_GW" = "$GATEWAYS" ]; then
        echo "Mesh has $CURR_GW gateways."
        break;
    fi;
    echo "Attempt $attempt/60"
    if [ $attempt -eq 60 ]; then
        echo "Scaling timed out."
        exit 1
    fi;
    sleep 3
done
