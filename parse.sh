
rm /tmp/hyperfoil.csv /tmp/cpu.csv
for file in $(ls -1 /tmp/runs/*.json); do
# for file in $(find /tmp/runs -maxdepth 1 -iname '003[7-C]*'); do
    jq -r '.hyperfoil.info.id as $id | .hyperfoil.info.description as $d | .hyperfoil.stats[] | select(.phase == "steady") | [ $id, .name, (1000 * .total.summary.requestCount / (.total.end - .total.start)), $d ] | @csv' $file | tr -d '"' >> /tmp/hyperfoil.csv
    jq -r '.hyperfoil.info.id as $id | .hyperfoil.info.description as $description | [ .cpu.data[].cpuinfo[] ] | group_by(.node) | .[] | { node: .[0].node, usage: [1 - .[].idle/56] | .[-12:-1] | max } | [ $id, .node, .usage, $description ] | @csv' $file | tr -d '"' >> /tmp/cpu.csv
done
