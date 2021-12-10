#!/bin/bash

#CONTROL_PLANE=istio-system
CONTROL_PLANE=mesh-control-plane
#INVENTORY=hosts.scalelab
INVENTORY=hosts.benchcluster
for dc in 40 ; do
    ansible-playbook -i $INVENTORY -e num_dc=$dc setup.yaml || exit 1
    for gateways in 1; do
        ./rescale.sh $CONTROL_PLANE 2 $gateways || exit 1
        for http2 in "false"; do
            for fork in "simple"; do
                ansible-playbook -i $INVENTORY -e expected_gateways=$gateways -e num_dc=$dc -e http2=$http2 -e fork=$fork test.yaml || exit 1
            done
        done
    done
done
# for dc in 40 80 160 320 ; do
#     ansible-playbook -i hosts.scalelab -e num_dc=$dc setup.yaml || exit 1
#     for gateways in 1 2 3 4; do
#         ./rescale.sh $CONTROL_PLANE 4 $gateways || exit 1
#         for http2 in "true" "false"; do
#             for fork in "simple" "db" "proxy"; do
#                 ansible-playbook -i hosts.scalelab -e expected_gateways=$gateways -e num_dc=$dc -e http2=$http2 -e fork=$fork test.yaml || exit 1
#             done
#         done
#     done
# done
