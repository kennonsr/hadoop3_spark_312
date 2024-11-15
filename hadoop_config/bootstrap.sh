#!/bin/bash
: ${HADOOP_HOME:=/usr/local/hadoop}
sudo bash $HADOOP_HOME/etc/hadoop/hadoop-env.sh

rm /tmp/*.pid
service ssh start
# $HADOOP_PREFIX/sbin/start-dfs.sh

# Launch bash console
/bin/bash
