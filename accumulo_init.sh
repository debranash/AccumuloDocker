#!/bin/sh
/root/installs/accumulo-1.6.4/bin/accumulo init << EOF
accumulo-instance
password
password
EOF
sed -i 's/localhost/'"$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"'/g' ~/installs/accumulo-1.6.4/conf/masters
sed -i 's/localhost/'"$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"'/g' ~/installs/accumulo-1.6.4/conf/slaves
sed -i 's/localhost/'"$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"'/g' ~/installs/accumulo-1.6.4/conf/gc
sed -i 's/localhost/'"$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"'/g' ~/installs/accumulo-1.6.4/conf/tracers
sed -i 's/localhost/'"$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"'/g' ~/installs/accumulo-1.6.4/conf/monitor
