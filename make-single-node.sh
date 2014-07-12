#!/usr/bin/env bash

# Add hadoop user
sudo addgroup hadoop
sudo adduser --ingroup hadoop hduser
echo hduser:hduser | sudo chpasswd
sudo adduser hduser sudo

# Set up ssh for hduser
sudo -u hduser ssh-keygen -t rsa -P '' -f /home/hduser/.ssh/id_rsa
sudo sh -c  "cat /home/hduser/.ssh/id_rsa.pub >> /home/hduser/.ssh/authorized_keys"
# Prevent ssh setup questions
sudo sh -c  "printf 'NoHostAuthenticationForLocalhost yes
Host *
    StrictHostKeyChecking no' > /home/hduser/.ssh/config"

# Download and install java jdk required for Hadoop.
sudo apt-get update
sudo apt-get install -y openjdk-7-jdk
sudo ln -s java-7-openjdk-amd64 /usr/lib/jvm/jdk
# Modify JAVA_HOME 
cd /usr/local/hadoop/etc/hadoop
sudo -u hduser sed -i.bak s=\${JAVA_HOME}=/usr/lib/jvm/jdk/=g hadoop-env.sh

# Download Hadoop to the vagrant shared directory if it doesn't exist yet
cd /vagrant
HADOOP_VERSION="2.4.1"
if [ ! -f hadoop-$HADOOP_VERSION.tar.gz ]; then
	wget http://apache.osuosl.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz
fi

# Unpack hadoop and install in /usr/local
if [ ! -d hadoop-$HADOOP_VERSION ]; then
	sudo tar vxzf hadoop-2.4.1.tar.gz
fi
cp hadoop-$HADOOP_VERSION /usr/local && cd /usr/local
sudo mv hadoop-2.4.1 hadoop
sudo chown -R hduser:hadoop hadoop

# Export Hadoop variables
sudo sh -c 'echo export JAVA_HOME=/usr/lib/jvm/jdk/ >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_INSTALL=/usr/local/hadoop >> /home/hduser/.bashrc'
sudo sh -c 'echo export PATH=\$PATH:\$HADOOP_INSTALL/bin >> /home/hduser/.bashrc'
sudo sh -c 'echo export PATH=\$PATH:\$HADOOP_INSTALL/sbin >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_MAPRED_HOME=\$HADOOP_INSTALL >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_COMMON_HOME=\$HADOOP_INSTALL >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_HDFS_HOME=\$HADOOP_INSTALL >> /home/hduser/.bashrc'
sudo sh -c 'echo export YARN_HOME=\$HADOOP_INSTALL >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_COMMON_LIB_NATIVE_DIR=\$\{HADOOP_INSTALL\}/lib/native >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_OPTS=\"-Djava.library.path=\$HADOOP_INSTALL/lib\" >> /home/hduser/.bashrc'

# Modify JAVA_HOME 
cd /usr/local/hadoop/etc/hadoop
sudo -u hduser sed -i.bak s=\${JAVA_HOME}=/usr/lib/jvm/jdk/=g hadoop-env.sh
pwd

# Check that Hadoop is installed
/usr/local/hadoop/bin/hadoop version

# Edit configuration files
sudo -u hduser sed -i.bak 's=<configuration>=<configuration>\<property>\<name>fs\.default\.name\</name>\<value>hdfs://localhost:9000\</value>\</property>=g' core-site.xml 
sudo -u hduser sed -i.bak 's=<configuration>=<configuration>\<property>\<name>yarn\.nodemanager\.aux-services</name>\<value>mapreduce_shuffle</value>\</property>\<property>\<name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>\<value>org\.apache\.hadoop\.mapred\.ShuffleHandler</value>\</property>=g' yarn-site.xml
  
sudo -u hduser cp mapred-site.xml.template mapred-site.xml
sudo -u hduser sed -i.bak 's=<configuration>=<configuration>\<property>\<name>mapreduce\.framework\.name</name>\<value>yarn</value>\</property>=g' mapred-site.xml
 
cd ~
sudo mkdir -p mydata/hdfs/namenode
sudo mkdir -p mydata/hdfs/datanode

cd /usr/local/hadoop/etc/hadoop
sudo -u hduser sed -i.bak 's=<configuration>=<configuration>\<property>\<name>dfs\.replication</name>\<value>1\</value>\</property>\<property>\<name>dfs\.namenode\.name\.dir</name>\<value>file:/home/hduser/mydata/hdfs/namenode</value>\</property>\<property>\<name>dfs\.datanode\.data\.dir</name>\<value>file:/home/hduser/mydata/hdfs/datanode</value>\</property>=g' hdfs-site.xml

su hduser -c "/usr/local/hadoop/bin/hdfs namenode -format -force"

# SSH into the box
#vagrant ssh -- -l hduser
#password: hduser

# Format Namenode
#hdfs namenode -format

# Start Hadoop Service
#sudo -u hduser start-dfs.sh
#sudo -u hduser start-yarn.sh

# Check status
#sudo -u hduser jps

# Example
# sudo -u hduser cd /usr/local/hadoop
# sudo -u hduser hadoop jar ./share/hadoop/mapreduce/hadoop-mapreduce-examples-2.2.0.jar pi 2 5

