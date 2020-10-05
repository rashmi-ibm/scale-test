#!/bin/bash

./istioctl manifest generate -f istio14.yaml | oc delete -f -

oc delete namespace istio-scale
oc delete namespace istio-system