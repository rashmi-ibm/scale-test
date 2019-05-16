# Istio/Maistra scalability tests

To get this benchmark running:

1. Install OCP and Ansible
2. Login to OCP: `oc login -u system:admin`
3. Install Istio: https://maistra.io/docs/getting_started/install/
    - In `controlplane/basic-install` set `ior_enabled: true`
    - I had trouble with `clusterrole istio-sidecar-injector-istio-system` - this was not correctly created and I had to fix it manually, applying:
```
      apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: istio-sidecar-injector-istio-system
  labels:
    app: istio-sidecar-injector
    release: istio
    istio: sidecar-injector
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["admissionregistration.k8s.io"]
  resources: ["mutatingwebhookconfigurations"]
  verbs: ["get", "list", "watch", "patch", "create" ]
```
4. You might need to add the policies:
   ```
   oc adm policy add-scc-to-user anyuid -z istio-ingress-service-account -n istio-system
   oc adm policy add-scc-to-user anyuid -z default -n istio-system
   oc adm policy add-scc-to-user anyuid -z prometheus -n istio-system
   oc adm policy add-scc-to-user anyuid -z istio-egressgateway-service-account -n istio-system
   oc adm policy add-scc-to-user anyuid -z istio-citadel-service-account -n istio-system
   oc adm policy add-scc-to-user anyuid -z istio-ingressgateway-service-account -n istio-system
   oc adm policy add-scc-to-user anyuid -z istio-cleanup-old-ca-service-account -n istio-system
   oc adm policy add-scc-to-user anyuid -z istio-mixer-post-install-account -n istio-system
   oc adm policy add-scc-to-user anyuid -z istio-mixer-service-account -n istio-system
   oc adm policy add-scc-to-user anyuid -z istio-pilot-service-account -n istio-system
   oc adm policy add-scc-to-user anyuid -z istio-sidecar-injector-service-account -n istio-system
   oc adm policy add-scc-to-user anyuid -z istio-galley-service-account -n istio-system
   oc adm policy add-scc-to-user anyuid -z istio-security-post-install-account -n istio-system
   ```
5. Allow wildcard routes: `oc set env dc/router ROUTER_ALLOW_WILDCARD_ROUTES=true -n default`
6. Create hosts.* according to your system
7. Run the setup (now everything should be automatized):
    `ansible-playbook -i hosts.mysetup setup.yaml`
8. There seems to be a bug in IOR (MAISTRA-356) that is not resolved in the image I use. Therefore you have
   to manually fix the generated route: `oc get route -n istio-system -l maistra.io/generated-by=ior`
   `oc patch route -n istio-system app-gateway-xxxxx -p '{ "spec": { "port" : { "targetPort": 80 }}}'`
9. The script generates 20% of apps marked as canary. With only few nodes make sure you have some (`oc get po -l app.variant=canary`) and update deployment as necessary. TODO: this should be probably more deterministic
10. Start the test:
    `ansible-playbook -i hosts.mysetup test.yaml`

# TODO:

* HTTPS!

# Hints:

* Add `LOG_LEVEL=TRACE` do deploymentconfig env vars if you want mannequin to be logging on trace level
* Add `global.proxy.accessLogFile: /dev/stdout` to `controlplane/basic-install` or modify directly `configmap/istio` to have access logs in `istio-proxy` containers.
* Add `--proxyLogLevel trace` to sidecar args to get the most verbose logging from Envoy