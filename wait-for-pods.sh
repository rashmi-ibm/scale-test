#!/bin/bash

NAMESPACE=$1
POD_PATTERN=$2
NUM_DC=$3

while true; do
    RUNNING=$(oc get po -l app==scale-test -n $NAMESPACE --no-headers | grep "$POD_PATTERN" | wc -l)
    if [ $RUNNING -eq $NUM_DC ]; then
        echo "All pods are up."
        exit 0
    fi
    ZERO_RCS=$(oc get rc --no-headers | tr -s ' ' ' ' | grep '0 0 0' | cut -f 1 -d ' ')
    echo "Missing RCs: $ZERO_RCS"
    oc delete rc $ZERO_RCS
    sleep 15
done
