#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd)
folder=$(echo $path | awk -F/ '{print $NF}')
json=/root/logs/report-$folder
source /root/.bash_profile
source $path/env

version=$()
docker_status=$(docker inspect $CONTAINER | jq -r .[].State.Status)
local_height=$(( 16#$(curl -sX POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' $LOCAL_URL | jq -r .result.currentBlock | sed 's/0x//g') ))
network_height=$(( 16#$(curl -sX POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' $PUBLIC_URL | jq -r .result.currentBlock | sed 's/0x//g') ))

status=warning && message="syncing $local_height/$network_height (behind $(( $network_height - local_height )) )
[ $docker_status -ne "running" ] && status="error" message="docker not running ($docker_status)"

case $docker_status in
  running) status="ok" ;;
  *) status="error"; message="docker not running ($docker_status)" ;;
esac

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
        "version":"$version"
  }
}
EOF
cat $json
