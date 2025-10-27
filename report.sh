#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd)
folder=$(echo $path | awk -F/ '{print $NF}')
json=/root/logs/report-$folder
source /root/.bash_profile
source $path/env

version=$()
docker_status=$(docker inspect $CONTAINER | jq -r .[].State.Status)
geth_syncing=$(curl -sX POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' $URL1 | jq -r .result ) 
prysm_syncing=$(curl -s $URL2/eth/v1/node/syncing | jq -r .data.is_syncing)
prysm_distance=$(curl -s $URL2/eth/v1/node/syncing | jq -r .data.sync_distance)
#echo geth_syncing $geth_syncing
#echo prysm_syncing $prysm_syncing

status="ok"
if [ "$geth_syncing" != "false" ]
then 
 local_height=$(( 16#$(curl -sX POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' $URL1 | jq -r .result.currentBlock | sed 's/0x//g') ))
 network_height=$(( 16#$(curl -s POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest", false],"id":1}' $URL5 | jq -r .result.number | sed 's/0x//') ))
 diff=$(( $network_height - $local_height ))
 status="warning" && message="geth syncing $local_height/$network_height (behind $diff )"
fi

[ "$prysm_syncing" != "false" ] && status="warning" && message="prysm syncing"
[ "$docker_status" != "running" ] && status="error" message="docker not running ($docker_status)"

cat >$json << EOF
{
  "updated":"$(date --utc +%FT%TZ)",
  "measurement":"report",
  "tags": {
         "id":"$folder-$ID",
         "machine":"$MACHINE",
         "grp":"node",
         "owner":"$OWNER"
  },
  "fields": {
        "network":"$NETWORK",
        "chain":"$CHAIN",
        "status":"$status",
        "message":"$message",
        "url":"$URL3 $URL4",
        "version":"$version",
        "m1":"geth behind $diff, prysm behind prysm_distance"
  }
}
EOF
cat $json | jq
