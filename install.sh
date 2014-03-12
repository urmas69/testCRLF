#!/bin/bash

NODE_VERSION=v0.10.2
MONGODB_VERSION=2.4.9
REDIS_VERSION=2.8.7

check_ip6(){
    #IP6MODS=`lsmod |grep ip6|wc -l`
    IP6MODS=`netstat -npl|grep tcp6|wc -l`
    #echo $IP6MODS
    if [ $IP6MODS -gt 0 ]; then
    echo "*****************************************"
    echo " 0. first disable ip6"
    echo "*****************************************"
    echo How to turn off IPv6
    echo Append ipv6.disable=1 to the GRUB_CMDLINE_LINUX variable in /etc/default/grub.
    echo Run update-grub and reboot.
    exit
    fi
}

test(){

var="d"
if [ -n "$var" ]; then echo "var is not empty"; fi

    if [ -n "$test3" ] ;then
        echo "a) test2 is NOT empty"
    fi
    test2="d"
    if [ -n $test2 ] ;then
        echo "b) test2 is NOT empty"
    else
        echo "b) test2 is empty"
    fi

    echo "cores: $test2";
}

#test
#exit

prerequists(){
    echo "*****************************************"
    echo " Prerequisites: Install updates, set time zones, install GCC and make"
    echo "*****************************************"
    apt-get update
    apt-get install build-essential git iptables-persistent default-jre tcl
}

install_node() {
    echo
    echo "*****************************************"
    echo " Node"
    echo "*****************************************"
    node_installed_version=""
    if [ ! -z $(command -v node) ] ;then
        node="$(which node)"
        node_installed_version=$($node --version)
    fi

    echo "Installed version of $node is $node_installed_version (expected $NODE_VERSION)"
    #return
    if [ $node_installed_version \< $NODE_VERSION ] ;then
       cd
       #bar_cat -c 'apt-get install python g++ make  2>&1 >/dev/null'
       apt-get install python g++ make| bar -n #|xargs -L 1 |xargs -I@ echo -n "." && echo
       #return
       mkdir ~/nodejs && cd $_
       wget -N http://nodejs.org/dist/node-latest.tar.gz
       bar -n  node-latest.tar.gz | tar xzf -
       #tar xzvf node-latest.tar.gz |xargs -L 30 |xargs -I@ echo -n "." && echo
       cd `ls -d --color=never node-v*`
       echo "configure node"
       ./configure  2>&1 >/dev/null | bar -n
       #./configure |xargs -L 2 |xargs -I@ echo -n "." && echo
       echo "make node"
       make -j$CORES install 2>&1 >/dev/null | bar -n
       #make -j$CORES install #|xargs -L 10 |xargs -I@ echo -n "." && echo
       echo "Installed version of $node is $($node --version)"
    fi
}



install_mongodb() {
    echo
    echo "*****************************************"
    echo "  Mongodb"
    echo "*****************************************"
    mongodb_installed_version=""
    if [ ! -z $(command -v mongod) ] ;then
        mongod="$(which mongod)"
        mongodb_installed_version=$($mongod --version | awk '/^db/ {print $3}' | tr -d "[v,]" )
    fi

    echo "Installed version of $mongod is $mongodb_installed_version (expected $MONGODB_VERSION)"
    if [ $mongodb_installed_version \< $MONGODB_VERSION ] ;then
        cd
        apt-get install libssl-dev git-core build-essential scons
        rm -rf mongo
        git clone git://github.com/mongodb/mongo.git
        cd mongo
        git tag -l 2>&1 >/dev/null
        #echo $CORES
        git checkout r$MONGODB_VERSION
        #echo r$MONGODB_VERSION
        #return
        echo "build mongodb"
        scons --ssl --jobs $CORES all 2>&1 >/dev/null | bar -n
        echo "install mongodb"
        scons --ssl --jobs $CORES install 2>&1 >/dev/null | bar -n
        cd
        mongod="$(which mongod)"
        echo "Installed version of $mongod is $($mongod --version)"
    fi
}

create_red(){
    echo
    echo "*****************************************"
    echo " 4. user red"
    echo "*****************************************"
    if id -u red >/dev/null 2>&1 ;then
        echo "user: red exists"
    else
        groupadd -g 1000 red
        useradd -d /home/red -u 1000 -g red -m -s /bin/bash red
        cp ~/.bash_profile /home/red/
        passwd red
    fi
}
# red help functions
sync_webserver(){
    if [ -d /home/red/redserver ] ;then
      echo "redserver already exists"
    else
      git clone https://github.com/redmedical/redserver
      rm -rf redserver/.git*
    fi

    # can't do it on github
    #git archive --format=tar --remote=git@github.com:redmedical/redserver.git HEAD | tar xf -
    # extremely slow
    #svn export --username urmas69 --password red#kumma69# --non-interactive  --force https://github.com/redmedical/redserver/trunk redserver

    git clone --depth=1 https://github.com/redmedical/redserver redserver
    rm -rf redserver/.git*
    rsync -rlptDzvu --exclude=fachinfo/ dev.redmedical.de:/home/red/webroot/ /home/red/webroot/


    rsync -rlptDzvu --exclude=fachinfo/ dev.redmedical.de:/home/red/webroot/ /home/red/webroot/
}

check_ip6

CORES=`grep -c processor /proc/cpuinfo`

read -r -n1 -p "Install node ? [y/N]" install_node_yes
[ "$install_node_yes" == "y" ] && install_node

read -r -n 1 -p "Install mongodb ? [y/N]" install_mongodb_yes
[ "$install_mongodb_yes" == "y" ] && install_mongodb

create_red

read -n1 -p "Install redis ? [y/N]" install_redis_yes
redis_installed_version=""
if [ -f /home/red/redis/src/redis-server ] ;then
 redis_installed_version=$(/home/red/redis/src/redis-server --version|awk '/^Redis/ {print $3}'|tr -d "[v=,]")
fi
if [ ${redis_installed_version} \< $REDIS_VERSION ] ;then
   [[ -f /etc/init.d/redis-server ]] && /etc/init.d/redis-server stop
fi

# as user red
su - red <<EOSU
do_install_redis() {
    echo
    echo "*****************************************"
    echo "  Redis"
    echo "*****************************************"

    echo "Installed version of redis is $redis_installed_version (expected $REDIS_VERSION)"

    if [  "$redis_installed_version" \< $REDIS_VERSION ] ;then
        cd
        rm -rf redis
        wget http://download.redis.io/redis-stable.tar.gz
        tar xvzf redis-stable.tar.gz  2>&1 >/dev/null
        rm -rf redis*.gz
        mv redis-stable redis
        cd redis
        make -j$CORES

        #(test) promt geht hier nicht ?
        read -r -n 1 -p "test ? [y/N]" YESNO
        [ "YESNO" == "y" ]  &&  make test
        cd
    fi
}

cd
pwd

#echo -e "Install redis ? [y/N]"
#read install_redis_yes
#echo "install_redis_yes $install_redis_yes"
[ "$install_redis_yes" == "y" ] && do_install_redis

 [ -d ~/log ] || mkdir ~/{log,data}
 [ -d ~/webroot ] || mkdir ~/webroot

 [ -f ~/.netrc ] || {
    echo -n "Git User Name:"
    read gitlogin
    echo -n "Git Password:"
    read gitpassword

    echo machine github.com login $gitlogin password $gitpassword > ~/.netrc
    chmod 600 ~/.netrc
 }

cd
 [ -d ~/redserver ] || git clone --depth=1 https://github.com/redmedical/redserver redserver

cd ~/webroot
 [ -d ./redclient ] || git clone --depth=1 https://github.com/redmedical/redclient redclient
 [ -d ./redcommon ] || git clone --depth=1 https://github.com/redmedical/redcommon redcommon
 [ -d ./reddemoclient ] || git clone --depth=1 https://github.com/redmedical/reddemoclient reddemoclient
 #redconnector
#cd
# rsync -rlptDzvu dev.redmedical.de:/home/red/redsolr/ ~/redsolr/


EOSU

# ssh agent forwarding root
read -r -n1 -p "Install solr ? [y/N]" install_solr_yes
[ "$install_solr_yes" == "y" ] &&  rsync -uav dev.redmedical.de:/home/red/redsolr/ /home/red/redsolr/

rsync -uav dev.redmedical.de:/home/red/webroot/redconnector/ /home/red/webroot/redconnector/


#init
apt-get install chkconfig

[ "$install_mongodb_yes" == "y" ] && {
  cp /home/red/redserver/init.d/mongodb /etc/init.d/
  chkconfig --add mongodb
  /etc/init.d/mongodb start
}

whoami

[ "$install_redis_yes" == "y" ] && {
 cp /home/red/redserver/init.d/redis-server /etc/init.d/
 chmod +x /etc/init.d/redis-server
 #cp /home/red/redserver/init.d/default/redis-server /etc/default/
 chkconfig --add redis-server
 /etc/init.d/redis-server start
}

[ "$install_solr_yes" == "y" ] && {
 cp /home/red/redserver/init.d/solr /etc/init.d/
 chkconfig --add solr
 /etc/init.d/solr start
}

exit


#as root
iptables-restore < /home/red/redserver/shell/iptables.rules.v4

#EOSU
echo "install_redis_yes $install_redis_yes"




