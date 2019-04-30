# Istio/Maistra scalability tests

To get this benchmark running:

1. Install OCP and Ansible
2. Login to OCP: `oc login -u system:admin`
3. Install Istio: https://maistra.io/docs/getting_started/install/
    - In `controlplane/basic-install` set `ior_enabled: true`
4. Create hosts.* according to your system
5. Run the setup (now everything should be automatized):
    `ansible-playbook -i hosts.mysetup setup.yaml`
6. There seems to be a bug in IOR (MAISTRA-356) that is not resolved in the image I use. Therefore you have
   to manually fix the generated route: `oc get route -n istio-system -l maistra.io/generated-by=ior`
   Edit this route and set `spec.port.targetPort: 80`.
7. The script generates 20% of apps marked as canary. With only few nodes make sure you have some (`oc get po -l app.variant=canary`) and update deployment as necessary. TODO: this should be probably more deterministic
8. Start the test:
    `ansible-playbook -i hosts.mysetup test.yaml`

# TODO:

* db call seems to fail about 30% of time
* proxy calls still return 404 - seems like port 4040 became blocked when I moved the service there?
* HTTPS!

# Hints:

* Add `LOG_LEVEL=TRACE` do deploymentconfig env vars if you want mannequin to be logging on trace level
* Add `global.proxy.accessLogFile: /dev/stdout` to `controlplane/basic-install` to have access logs in `istio-proxy` containers.