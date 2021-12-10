rm /tmp/hyperfoil.csv /tmp/cpu.csv
# for file in $(ls -1 /tmp/runs/*.json); do
for dir in $(find /tmp/runs -maxdepth 1 -iname '00F[C-F]*') $(find /tmp/runs -maxdepth 1 -iname '01*'); do
    jq -r '.hyperfoil.info.id as $id | .hyperfoil.info.description as $d | .hyperfoil.stats[] | select(.phase == "steady") | [ $id, .name, (1000 * .total.summary.requestCount / (.total.end - .total.start)), $d ] | @csv' $dir/result.json | tr -d '"' >> /tmp/hyperfoil.csv
    jq -r '.hyperfoil.info.id as $id | .hyperfoil.info.description as $description | [ .cpu.data[].cpuinfo[] ] | group_by(.node) | .[] | { node: .[0].node, usage: [1 - .[].idle/56] | .[-12:-1] | max } | [ $id, .node, .usage, $description ] | @csv' $dir/result.json | tr -d '"' >> /tmp/cpu.csv
done
