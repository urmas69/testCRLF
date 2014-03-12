#!/bin/bash

NODE_VERSION=v0.10.2
MONGODB_VERSION=2.4.9
REDIS_VERSION=2.8.7

myrun(){
  echo "run:"
  $1
}

CORES=`grep -c processor /proc/cpuinfo`

read -r -n1 -p "Install node ? [y/N]" install_node_yes

echo  "Install node ? $install_node_yes"

myrun 'ls -la /etc'

su red <<EOSU
cd
pwd
whoami
echo

    echo -n "Git User Name:"
    read gitlogin
    echo -n "Git Password:"
    read gitpassword


EOSU




echo "finish"
