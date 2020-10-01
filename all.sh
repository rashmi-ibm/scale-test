CONTROL_PLANE=istio-system

for gateways in 1 2 4; do
    oc scale -n $CONTROL_PLANE deployment istio-ingressgateway --replicas=$gateways
    for attempt in $(seq 1 60); do
        CURR_GW=$(oc get po -n $CONTROL_PLANE -l app=istio-ingressgateway -o json | jq '.items | length')
        if [ "$CURR_GW" = "$gateways" ]; then
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
    INVENTORY=hosts.scalelab
    for num_dc in 10 20 40 80 160 320; do
        ansible-playbook -i $INVENTORY -e num_dc=$num_dc setup.yaml -vv || exit 1
        ansible-playbook -i $INVENTORY -e num_dc=$num_dc test.yaml -vv || exit 1
    done
done