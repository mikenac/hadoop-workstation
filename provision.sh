#!/bin/bash


# this will register with RHEL network
sudo chmod +x /vagrant/register.sh
/vagrant/register.sh

# update the system
sudo yum -y update

# docker like environment variables
ENV () {
	local name=$1
	local val=$2
	local file=/etc/profile.d/local_env.sh

	if [ ! -f $file ];
	then
		echo "#!/bin/bash" | sudo tee -a $file >> /dev/null
		sudo chmod +x $file
	fi
	echo "export $name=$val" | sudo tee -a $file >> /dev/null
	source /etc/profile.d/local_env.sh
}

# install Oracle Java 8
if [ "x$JAVA_HOME" == "x" ];
then
	echo "Installing Oracle Java 8"
	sudo yum -y install java-1.8.0-oracle-devel.x86_64 wget
	ENV JAVA_HOME '/usr/lib/jvm/java'
fi

# disable the firewall
sudo systemctl stop firewalld
sudo systemctl disable firewalld

echo "Base provisioning complete."

# hadoop
echo "Installing Hadoop"
RESDIR=/vagrant/resources
HADOOP_HOME=/usr/lib/hadoop
HADOOP_VERSION=2.7.3
ENV HADOOP_HOME $HADOOP_HOME
ENV HADOOP_PREFIX $HADOOP_HOME
ENV HADOOP_INSTALL $HADOOP_PREFIX
ENV HADOOP_MAPRED_HOME $HADOOP_PREFIX
ENV HADOOP_COMMON_HOME $HADOOP_PREFIX
ENV HADOOP_HDFS_HOME $HADOOP_PREFIX
ENV YARN_HOME $HADOOP_PREFIX
ENV HADOOP_OPTS "-DJava.library.path=$HADOOP_PREFIX/lib"
ENV HADOOP_COMMON_LIV_NATIVE_DIR $HADOOP_PREFIX/lib/native
ENV PATH '$PATH:$HADOOP_PREFIX/bin:$HADOOP_PREFIX/sbin'
HADOOP_FILE=hadoop-$HADOOP_VERSION.tar.gz

if [ ! -f $RESDIR/$HADOOP_FILE ];
then
	wget http://apache.mirrors.pair.com/hadoop/common/hadoop-$HADOOP_VERSION/$HADOOP_FILE -O $RESDIR/$HADOOP_FILE
fi

echo $RESDIR/$HADOOP_FILE
tar -xf $RESDIR/$HADOOP_FILE
sudo mkdir $HADOOP_PREFIX
sudo ln -s $HADOOP_PREFIX/etc/hadoop /etc/hadoop
mv hadoop-$HADOOP_VERSION/* /usr/lib/hadoop
rm -rf hadoop-$HADOOP_VERSION

sudo chmod +x $HADOOP_PREFIX/sbin/start-dfs.sh
sudo chmod +x $HADOOP_PREFIX/sbin/start-yarn.sh

# add hadoop user
sudo groupadd hdfs
sudo adduser hdfs -g hdfs
sudo chown -R hdfs:hdfs $HADOOP_PREFIX 
sudo chown -R hdfs:hdfs /etc/hadoop
sudo -u hdfs ssh-keygen -t rsa -P '' -f /home/hdfs/.ssh/id_rsa
sudo -u hdfs cat /home/hdfs/.ssh/id_rsa.pub >> /home/hdfs/.ssh/authorized_keys
sudo chown -R hdfs:hdfs /home/hdfs 
sudo chmod 700 /home/hdfs/.ssh
sudo chmod 600 /home/hdfs/.ssh/*
sudo mkdir /var/log/hadoop
sudo chown hdfs:hdfs /var/log/hadoop
sudo mkdir /var/log/nodemanager
sudo chown hdfs:hdfs /var/log/nodemanager


# add a generic developer use to the system and give them acces to hdfs and sudo rights
sudo adduser developer -G wheel,hdfs
sudo usermod -p "b2Z6MvXdSE5e." developer # Rocket_99999

# copy the configuration files
sudo cp /vagrant/conf/hadoop/* /etc/hadoop
sudo cp /vagrant/conf/ssh/* /home/hdfs/.ssh
sudo chown hdfs:hdfs /home/hdfs/.ssh/config
sudo cp /vagrant/conf/user/* /home/developer


# format the namenode
sudo -u hdfs $HADOOP_PREFIX/bin/hdfs namenode -format


# startup the deamons
sudo cp /vagrant/conf/init/* /usr/lib/systemd/system/
sudo systemctl enable hadoop
sudo systemctl enable yarn
sudo systemctl start hadoop
sudo systemctl start yarn

# create hdfs directories for hdfs use
sudo -u hdfs $HADOOP_PREFIX/bin/hdfs dfs -mkdir /user
sudo -u hdfs $HADOOP_PREFIX/bin/hdfs dfs -mkdir /user/hdfs

echo "HADOOP is installed"

echo "Installing Zookeeper"
ZK_VERSION=3.4.10
ZK_HOME=/usr/lib/zookeeper
ZK_FILE=zookeeper-$ZK_VERSION.tar.gz
if [ ! -f $RESDIR/$ZK_FILE ];
then
	wget http://apache.mirrors.lucidnetworks.net/zookeeper/zookeeper-$ZK_VERSION/zookeeper-$ZK_VERSION.tar.gz -O $RESDIR/$ZK_FILE
fi
tar -xf $RESDIR/$ZK_FILE
sudo mkdir $ZK_HOME
sudo cp zookeeper-$ZK_VERSION/* $ZK_HOME
sudo rm -rf zookeeper-$ZK_VERSION
sudo cp /vagrant/conf/zookeeper/* $ZK_HOME/conf
sudo mkdir /var/zookeeper
chown -R hdfs:hdfs $ZK_HOME
chown hdfs:hdfs /var/zookeeper

echo "Starting zookeeper"
sudo systemctl enable zookeeper
sudo systemctl start zookeeper


echo "Installing HiveServer2"
HIVE_VERSION=2.1.1
HIVE_FILE=apache-hive-$HIVE_VERSION-bin.tar.gz
HIVE_HOME=/usr/lib/hive
ENV HIVE_HOME $HIVE_HOME
if [ ! -f $RESDIR/$HIVE_FILE ];
then 
	wget http://apache.mirrors.ionfish.org/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz -O $RESDIR/$HIVE_FILE
fi
tar -xf $RESDIR/$HIVE_FILE
sudo mkdir $HIVE_HOME
sudo cp apache-hive-$HIVE_VERSION-bin/* $HIVE_HOME 
sudo rm -rf apache-hive-$HIVE_VERSION-bin
chown -R hdfs:hdfs $HIVE_HOME

# MYSQL for hive metastore
sudo yum -y install mysql-server
sudo systemctl enable mysqld
sudo systemctl start mysqld

# MYSQL JDBC
sudo yum -y install mysql-connector-java
sudo ln -s /usr/share/java/mysql-connector-java.jar $HIVE_HOME/lib/mysql-connector-java.jar

# create metastore database and users. Notice the user cannot change schema.
SQL="
CREATE DATABASE IF NOT EXISTS 'metastore';
USE metastore;
SOURCE/$HIVE_HOME/scripts/metastore/upgrade/mysql/hive-schema-2.1.0.mysql.sql;
CREATE USER 'hive' @ 'localhost' IDENTIFIED BY 'hive';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'hive'@'localhost';
GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES,EXECUTE ON metastore.* TO 'hive'@'localhost';
FLUSH PRIVILEGES; 
"
sudo mysql -uroot -p -e $SQL

echo "Starting HiveServer2"
# TODO: There is not good way to stop hiveserver, except killing the process.
# Make a script to do this and add its invocation to the hiverserver2.service file.

# TODO: Hive is not added to the path until the path can be replaced. Add this after.
sudo systemctl enable hiveserver2
sudo systemctl start hiveserver2


















