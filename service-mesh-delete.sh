#!/bin/bash

oc delete smcp -n mesh-control-plane basic-install
oc delete subs -n openshift-operators servicemeshoperator kiali-ossm jaeger-product elasticsearch-operator
oc delete namespace mesh-control-plane mesh-scale

# These two should be removed by the operator, so just in case...
oc delete mutatingwebhookconfiguration -l app.kubernetes.io/instance=mesh-control-plane
oc delete validatingwebhookconfiguration -l app.kubernetes.io/instance=mesh-control-plane

# Operator itself seems to persist
oc delete deployment -n openshift-operators istio-operator
oc delete daemonset -n openshift-operators istio-node
