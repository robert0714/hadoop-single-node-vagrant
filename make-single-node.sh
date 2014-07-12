#!/usr/bin/env bash

# Set _DEBUG to true to show debug statements.
_DEBUG=false
function DEBUG()
{
 [ "$_DEBUG" == true ] &&  $@
}

# Add hadoop user
DEBUG echo "##> Create hduser."
sudo addgroup hadoop
sudo adduser --ingroup hadoop hduser
DEBUG echo hduser:hduser | sudo chpasswd
sudo adduser hduser sudo
DEBUG echo "##> Created user hduser."

# Set up ssh for hduser
DEBUG echo "##> Set up SSH for hduser."
sudo -u hduser ssh-keygen -t rsa -P '' -f /home/hduser/.ssh/id_rsa
sudo sh -c  "cat /home/hduser/.ssh/id_rsa.pub >> /home/hduser/.ssh/authorized_keys"
# Prevent ssh setup questions
sudo sh -c  "printf 'NoHostAuthenticationForLocalhost yes
Host *
    StrictHostKeyChecking no' > /home/hduser/.ssh/config"
DEBUG echo "##> SSH for hduser ready."

# Download and install java jdk required for Hadoop.
DEBUG echo "##> Start installing Java."
sudo apt-get update
sudo apt-get install -y openjdk-7-jdk
sudo ln -s java-7-openjdk-amd64 /usr/lib/jvm/jdk
DEBUG echo "##> Java installed."

# Download Hadoop to the vagrant shared directory if it doesn't exist yet
DEBUG echo "##> Start installing Hadoop."
cd /vagrant
HADOOP_VERSION="2.4.1"
if [ ! -f hadoop-$HADOOP_VERSION.tar.gz ]; then
	wget http://apache.osuosl.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz
fi
DEBUG echo "##> Downloaded Hadoop"

# Unpack hadoop and install in /usr/local
if [ ! -d hadoop-$HADOOP_VERSION ]; then
	sudo tar vxzf hadoop-$HADOOP_VERSION.tar.gz
fi
sudo rm -r hadoop-$HADOOP_VERSION/share/doc/
DEBUG echo "##> Unpacked hadoop"

sudo cp -r hadoop-$HADOOP_VERSION /usr/local
cd /usr/local
sudo mv hadoop-$HADOOP_VERSION hadoop
sudo chown -R hduser:hadoop hadoop
DEBUG echo "##> Installed Hadoop in /usr/local"

# Check that Hadoop is installed
/usr/local/hadoop/bin/hadoop version

# Modify JAVA_HOME 
cd /usr/local/hadoop/etc/hadoop
sudo -u hduser sed -i.bak s=\${JAVA_HOME}=/usr/lib/jvm/jdk/=g hadoop-env.sh

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

DEBUG echo "##> Start namenode formatting."
su hduser -c "/usr/local/hadoop/bin/hdfs namenode -format -force"
DEBUG echo "##> Finished namenode formatting."

# SSH into the box
#vagrant ssh -- -l hduser
#password: hduser

# Format Namenode
#hdfs namenode -format

# Start Hadoop Service
#start-dfs.sh
#start-yarn.sh

# Check status
#jps

# Example
# sudo -u hduser cd /usr/local/hadoop
# sudo -u hduser hadoop jar ./share/hadoop/mapreduce/hadoop-mapreduce-examples-2.2.0.jar pi 2 5

