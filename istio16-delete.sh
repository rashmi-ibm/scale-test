#!/bin/bash

oc delete istiooperators.install.istio.io -n istio-system basic-install
./istioctl operator remove

oc delete namespace istio-scale
oc delete namespace istio-system