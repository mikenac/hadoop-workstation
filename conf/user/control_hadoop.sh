#!/bin/bash

# get commands
while [[ $# -gt 1 ]]
do
key="$1"

case $key in 
	 --start)
	ACTION="start"
	shift
	;;
	--stop)
	ACTION="stop"
	shift
	;;
	--restart)
 	ACTION="restart"
 	;;
esac

if [ $ACTION == "start" ];
then
	sudo -u hdfs $HADOOP_PREFIX/sbin/start-dfs.sh
	sudo -u hdfs $HADOOP_PREFIX/sbin/start-yarn.sh
elif [ $ACTION == "stop" ];
then
	sudo -u hdfs $HADOOP_PREFIX/sbin/stop-dfs.sh
	sudo -u hdfs $HADOOP_PREFIX/sbin/stop-yarn.sh
elif [ $ACTION == "restart" ];
then
	sudo -u hdfs $HADOOP_PREFIX/sbin/stop-dfs.sh
	sudo -u hdfs $HADOOP_PREFIX/sbin/stop-yarn.sh
	sudo -u hdfs $HADOOP_PREFIX/sbin/start-dfs.sh
	sudo -u hdfs $HADOOP_PREFIX/sbin/start-yarn.sh
else
	echo "Unknown command. Pass --start, --stop, --restart"
fi
