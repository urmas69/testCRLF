#!/bin/bash

NODE_VERSION=0.10.2
MONGODB_VERSION=2.4.9
REDIS_VERSION=2.8.7

progress(){
  echo -n "$1: Please wait..."
  while true
  do
    echo -n "."
    sleep 5
  done
}

wrap(){

   progress $1 &
   # Save progress() PID
   # You need to use the PID to kill the function
   MYSELF=$!
   shift
   $@ >/dev/null 2>&1
   kill $MYSELF >/dev/null 2>&1
   echo -n "...done."
}

install_node() {
    echo
    echo "*****************************************"
    echo " Node "
    echo "*****************************************"
    node_installed_version=""
    if [ ! -z $(command -v node) ] ;then
        node="$(which node)"
        node_installed_version=$($node --version)
    fi

    echo "Installed version of $node is $node_installed_version (expected $NODE_VERSION)"
    #return
    if [ $node_installed_version \< $NODE_VERSION ] ;then

       wrap "install prerequists" apt-get install python g++ make
       echo
       mkdir ~/nodejs && cd $_
    fi
}

CORES=`grep -c processor /proc/cpuinfo`

read -r -n1 -p "Install node ? [y/N]" install_node_yes
[ "$install_node_yes" == "y" ] && install_node


echo  "Install node ? $install_node_yes"
echo "finish"
