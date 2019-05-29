#!/usr/bin/env bash
#  Install rsync
sudo apt-get install rsync

# Add hadoop user
sudo addgroup hadoop
sudo adduser --ingroup hadoop hduser
echo hduser:hduser | sudo chpasswd
sudo adduser hduser sudo

sudo -u hduser ssh-keygen -t rsa -P '' -f /home/hduser/.ssh/id_rsa
sudo sh -c  "cat /home/hduser/.ssh/id_rsa.pub >> /home/hduser/.ssh/authorized_keys"
# Prevent ssh setup questions
sudo sh -c  "printf 'NoHostAuthenticationForLocalhost yes
Host *
    StrictHostKeyChecking no' > /home/hduser/.ssh/config"

# Download java jdk
sudo apt-get update
sudo apt-get install -y openjdk-8-jdk
sudo ln -s java-8-openjdk-amd64 /usr/lib/jvm/jdk
sudo apt-get install -y nfs-common portmap

# Download Hadoop to the vagrant shared directory if it doesn't exist yet
cd /vagrant
if [ ! -f hadoop-2.9.2.tar.gz ]; then
	wget http://apache.osuosl.org/hadoop/common/hadoop-2.9.2/hadoop-2.9.2.tar.gz
fi
# Unpack hadoop and install
sudo tar vxzf hadoop-2.9.2.tar.gz -C /usr/local
cd /usr/local
sudo mv hadoop-2.9.2 hadoop
sudo chown -R hduser:hadoop hadoop

# Hadoop variables
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

# Edit configuration files
sudo -u hduser sed -i.bak 's=<configuration>=<configuration>\<property>\<name>fs\.default\.name\</name>\<value>hdfs://localhost:9000\</value>\</property>=g' core-site.xml 
sudo -u hduser sed -i.bak 's=<configuration>=<configuration>\<property>\<name>yarn\.nodemanager\.aux-services</name>\<value>mapreduce_shuffle</value>\</property>\<property>\<name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>\<value>org\.apache\.hadoop\.mapred\.ShuffleHandler</value>\</property>=g' yarn-site.xml
  
sudo -u hduser cp mapred-site.xml.template mapred-site.xml
sudo -u hduser sed -i.bak 's=<configuration>=<configuration>\<property>\<name>mapreduce\.framework\.name</name>\<value>yarn</value>\</property>=g' mapred-site.xml
 

sudo mkdir -p /home/hduser/mydata/hdfs/namenode
sudo mkdir -p /home/hduser/mydata/hdfs/datanode

sudo chown hduser:hadoop  -R /home/hduser/mydata


cd /usr/local/hadoop/etc/hadoop
sudo -u hduser sed -i.bak 's=<configuration>=<configuration>\<property>\<name>dfs\.replication</name>\<value>1\</value>\</property>\<property>\<name>dfs\.namenode\.name\.dir</name>\<value>file:/home/hduser/mydata/hdfs/namenode</value>\</property>\<property>\<name>dfs\.datanode\.data\.dir</name>\<value>file:/home/hduser/mydata/hdfs/datanode</value>\</property>=g' hdfs-site.xml

## You maybee see the problem of authentication error.
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
