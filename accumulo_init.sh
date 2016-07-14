#!/bin/sh
/root/installs/accumulo-1.6.5/bin/accumulo init << EOF
myinstance
password
password
EOF
sed -i 's/localhost/localhost\n'"$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"'/g' ~/installs/accumulo-1.6.5/conf/masters
sed -i 's/localhost/localhost\n'"$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')"'/g' ~/installs/accumulo-1.6.5/conf/slaves
