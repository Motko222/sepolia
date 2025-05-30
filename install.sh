#!/bin/bash

path=$(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd)
folder=$(echo $path | awk -F/ '{print $NF}')
cd $path

[ -f env ] cp env-sample env
nano env
source $path/env

cd /root
[ -d $WORKDIR ] && rm $WORKDIR
git clone $GIT
