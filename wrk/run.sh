#!/bin/sh

COMMAND=$1
FROM=$2
TO=$3
DURATION=$4
if [ -n "$5" ]; then
   C_CONNECTIONS=$5
   S_CONNECTIONS=`expr 4 \* $5`
else
   C_CONNECTIONS=100
   S_CONNECTIONS=400
fi
if [ -n "$6" ]; then
    C_RATE="-R $6"
    S_RATE="-R "`expr 4 \* $6`
fi

echo 'Running '$COMMAND' for '$DURATION' to app '$FROM' .. '$TO' using total '`expr \( $TO - $FROM + 1 \) \* 5 \* $C_CONNECTIONS`' connections.'

if [ $COMMAND == 'fortio' ]; then
    rm /tmp/fortio*.txt
    for i in $(seq $FROM $TO); do
        fortio load -k -qps 0 -c $S_CONNECTIONS -t $DURATION's' -H 'x-variant: stable' https://app-$i.mesh.apps.ocp.scalelab/mersennePrime?p=1 2> /tmp/fortio-$i-stable.txt &
        fortio load -k -qps 0 -c $C_CONNECTIONS -t $DURATION's' -H 'x-variant: canary' https://app-$i.mesh.apps.ocp.scalelab/mersennePrime?p=1 2> /tmp/fortio-$i-canary.txt &
    done

    wait
    echo > /tmp/requests
    for file in $(ls -1 /tmp/fortio-*.txt); do
        sed -n -e 's/.* \([0-9.]*\) qps$/\1/p' $file >> /tmp/requests;
    done;
    awk '{s+=$1} END {print s}' /tmp/requests
else
    rm /tmp/wrk*.txt

    for i in $(seq $FROM $TO); do
        $COMMAND $S_RATE -d $DURATION -t 4 -c $S_CONNECTIONS -H 'x-variant: stable' https://app-$i.mesh.apps.ocp.scalelab/mersennePrime?p=1 > /tmp/wrk-$i-stable.txt &
        $COMMAND $C_RATE -d $DURATION -t 1 -c $C_CONNECTIONS -H 'x-variant: canary' https://app-$i.mesh.apps.ocp.scalelab/mersennePrime?p=1 > /tmp/wrk-$i-canary.txt &
    done

    wait
    echo > /tmp/requests
    for file in $(ls -1 /tmp/wrk-*.txt); do
        sed -n 's/^ *\([0-9]*\) requests.*/\1/p' $file >> /tmp/requests;
    done;
    awk '{s+=$1} END {print s/'$DURATION'}' /tmp/requests
fi
