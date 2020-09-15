INVENTORY=hosts.scalelab
for num_dc in 10 20 40 80 160 320; do
    ansible-playbook -i $INVENTORY -e num_dc=$num_dc setup.yaml -vv || exit 1
    ansible-playbook -i $INVENTORY -e num_dc=$num_dc test.yaml -vv || exit 1
done

#jq -r '.hyperfoil.info.id as $id | .hyperfoil.info.description as $d | .hyperfoil.stats[] | select(.phase == "steady") | [ $id, .name, (1000 * .total.summary.requestCount / (.total.end - .total.start)), $d ] | @csv' public/report.json | tr -d '"'
#jq -r '.hyperfoil.info.id as $id | [ .cpu.data[].cpuinfo[] ] | group_by(.node) | .[] | { node: .[0].node, usage: [1 - .[].idle/56] | .[-12:-1] | max } | [ $id, .node, .usage ] | @csv'  public/report.json