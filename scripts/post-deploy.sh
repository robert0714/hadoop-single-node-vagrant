#!/bin/bash
# centos 7.6
value=$( grep -ic "entry" /etc/hosts )
if [ $value -eq 0 ]
then
echo "
################ hadoop-cookbook host entry ############
10.100.192.100  master
10.100.192.101  data-1
10.100.192.102  data-2
10.100.192.103  data-3
######################################################
" > /etc/hosts
fi
sudo  yum install epel-release -y
sudo  yum install -y java-1.8.0-openjdk  java-1.8.0-openjdk-devel 
sudo ln -s  /usr/lib/jvm/java-1.8.0-openjdk  /usr/lib/jvm/jdk

# Add hadoop user
sudo groupadd hadoop
sudo useradd -g hadoop hduser
echo hduser:hduser | sudo chpasswd
sudo adduser hduser sudo

sudo -u hduser ssh-keygen -t rsa -P '' -f /home/hduser/.ssh/id_rsa
sudo sh -c  "cat /home/hduser/.ssh/id_rsa.pub >> /home/hduser/.ssh/authorized_keys"
# Prevent ssh setup questions
sudo sh -c  "printf 'NoHostAuthenticationForLocalhost yes
 Host *  
    StrictHostKeyChecking no' > /home/hduser/.ssh/config"

# Download Hadoop to the vagrant shared directory if it doesn't exist yet
cd /vagrant
if [ ! -f hadoop-2.7.7.tar.gz ]; then
	wget https://archive.apache.org/dist/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz
fi
# Unpack hadoop and install
sudo tar vxzf hadoop-2.7.7.tar.gz -C /usr/local


# Install hadoop 
cd /usr/local
sudo mv hadoop-2.7.7 hadoop
sudo chown -R hduser:hadoop hadoop


# Hadoop variables
sudo sh -c 'echo export JAVA_HOME=/usr/lib/jvm/jdk/ >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_INSTALL=/usr/local/hadoop >> /home/hduser/.bashrc'
sudo sh -c 'echo export PATH=\$PATH:\$HADOOP_INSTALL/bin >> /home/hduser/.bashrc'
sudo sh -c 'echo export PATH=\$PATH:\$HADOOP_INSTALL/sbin >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_MAPRED_HOME=\$HADOOP_INSTALL >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_COMMON_HOME=\$HADOOP_INSTALL >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_HOME=\$HADOOP_INSTALL >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_HDFS_HOME=\$HADOOP_INSTALL >> /home/hduser/.bashrc'
sudo sh -c 'echo export YARN_HOME=\$HADOOP_INSTALL >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_COMMON_LIB_NATIVE_DIR=\$\{HADOOP_INSTALL\}/lib/native >> /home/hduser/.bashrc'
sudo sh -c 'echo export JAVA_LIBRARY_PATH=\${HADOOP_HOME\}/lib/native >> /home/hduser/.bashrc' 
sudo sh -c 'echo export HADOOP_OPTS=\"-Djava.library.path=\$HADOOP_INSTALL/lib\" >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_PREFIX=\$HADOOP_INSTALL >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_CONF_DIR=\$HADOOP_INSTALL/etc/hadoop >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_YARN_HOME=\$HADOOP_INSTALL >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_CLASSPATH=\${JAVA_HOME}/lib/tools.jar >> /home/hduser/.bashrc'


# Modify JAVA_HOME 
cd /usr/local/hadoop/etc/hadoop
sudo -u hduser sed -i.bak s=\${JAVA_HOME}=/usr/lib/jvm/jdk/=g hadoop-env.sh

# Edit configuration files
cd /usr/local/hadoop/etc/hadoop
sudo -u hduser sed -i.bak 's=<configuration>=<configuration>\<property>\<name>fs\.default\.name\</name>\<value>hdfs://master:9000\</value>\</property>=g'  core-site.xml 
sudo -u hduser sed -i.bak 's=<configuration>=<configuration>\<property>\<name>yarn\.nodemanager\.aux-services</name>\<value>mapreduce_shuffle</value>\</property>\<property>\<name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>\<value>org\.apache\.hadoop\.mapred\.ShuffleHandler</value>\</property>\<property>\<name>yarn\.resourcemanager\.resource\-tracker\.address</name>\<value>master\:8025</value>\</property>\<property>\<name>yarn\.resourcemanager\.scheduler\.address</name>\<value>master\:8030</value>\</property>\<property>\<name>yarn\.resourcemanager\.address</name>\<value>master\:8050</value>\</property>=g'  yarn-site.xml
  
sudo -u hduser cp mapred-site.xml.template mapred-site.xml
sudo -u hduser sed -i.bak 's=<configuration>=<configuration>\<property>\<name>mapred\.job\.tracker</name>\<value>master\:54311</value>\</property>=g' mapred-site.xml
 

sudo mkdir -p /home/hduser/mydata/hdfs/namenode
sudo mkdir -p /home/hduser/mydata/hdfs/datanode

sudo chown hduser:hadoop  -R /home/hduser/mydata


cd /usr/local/hadoop/etc/hadoop
sudo -u hduser sed -i.bak 's=<configuration>=<configuration>\<property>\<name>dfs\.replication</name>\<value>1\</value>\</property>\<property>\<name>dfs\.namenode\.name\.dir</name>\<value>file:/home/hduser/mydata/hdfs/namenode</value>\</property>\<property>\<name>dfs\.datanode\.data\.dir</name>\<value>file:/home/hduser/mydata/hdfs/datanode</value>\</property>=g' hdfs-site.xml
 

sudo sh -c 'echo master  > /usr/local/hadoop/etc/hadoop/masters'
sudo sh -c 'echo data-1 data-2 data-3 > /usr/local/hadoop/etc/hadoop/slaves'

echo 'You maybee see the problem of authentication error' 
## You maybee see the problem of authentication error.
su hduser -c "/usr/local/hadoop/bin/hdfs namenode -format -force"


# Download Scala to the vagrant shared directory if it doesn't exist yet
cd /vagrant
if [ ! -f scala-2.11.12.tgz ]; then
	wget https://www.scala-lang.org/files/archive/scala-2.11.12.tgz
fi
# Unpack Scala and install
sudo tar vxzf scala-2.11.12.tgz -C /usr/local
cd /usr/local
sudo mv scala-2.11.12 scala
sudo chown -R hduser:hadoop scala

# scala variables
sudo sh -c 'echo export SCALA_HOME=/usr/local/scala >> /home/hduser/.bashrc'
sudo sh -c 'echo export PATH=\$PATH:\$SCALA_HOME/bin >> /home/hduser/.bashrc'


# Download Spark to the vagrant shared directory if it doesn't exist yet
#  https://archive.apache.org/dist/spark/spark-2.0.0/spark-2.0.0-bin-hadoop2.7.tgz
#  http://apache.stu.edu.tw/spark/spark-2.4.3/spark-2.4.3-bin-hadoop2.7.tgz
 
cd /vagrant
if [ ! -f spark-2.0.2-bin-hadoop2.7.tgz ]; then
	wget https://archive.apache.org/dist/spark/spark-2.0.2/spark-2.0.2-bin-hadoop2.7.tgz
fi

# Unpack Spark and install
sudo tar vxzf spark-2.0.2-bin-hadoop2.7.tgz -C /usr/local
cd /usr/local
if [ ! -f spark ]; then
	sudo mv spark-2.0.2-bin-hadoop2.7    spark
	sudo chown -R hduser:hadoop spark
fi

# Spark variables
sudo sh -c 'echo export SPARK_HOME=/usr/local/spark >> /home/hduser/.bashrc'
sudo sh -c 'echo export PATH=\$PATH:\$SPARK_HOME/bin >> /home/hduser/.bashrc'
sudo sh -c 'echo export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$HADOOP_HOME/lib/native >> /home/hduser/.bashrc'

# Copy log4j template to log4j.properties
cd /usr/local/spark/conf/
if [ ! -f log4j.properties ]; then
	sudo cp   log4j.properties.template   log4j.properties
fi
 
sudo sed -i 's/log4j.rootCategory=INFO, console/log4j.rootCategory=WARN, console/g' /usr/local/spark/conf/log4j.properties    

# spark cluster configuration
sudo cp /usr/local/spark/conf/spark-env.sh.template /usr/local/spark/conf/spark-env.sh
sudo sh -c 'echo export SPARK_MASTER_IP=master >> /usr/local/spark/conf/spark-env.sh'
sudo sh -c 'echo export SPARK_WORKER_CORES=1 >> /usr/local/spark/conf/spark-env.sh'
sudo sh -c 'echo export SPARK_WORKER_MEMORY=512m >> /usr/local/spark/conf/spark-env.sh'
sudo sh -c 'echo export SPARK_EXECUTOR_INSTANCES=4 >> /usr/local/spark/conf/spark-env.sh'
sudo sh -c 'echo data-1 data-2 data-3 > /usr/local/spark/conf/slaves'


# Download Anaconda to the vagrant shared directory if it doesn't exist yet
cd /vagrant
if [ ! -f Anaconda2-4.3.1-Linux-x86_64.sh ]; then
	wget https://repo.continuum.io/archive/Anaconda2-4.3.1-Linux-x86_64.sh
fi
# Unpack Anaconda and install
sudo -u hduser  bash Anaconda2-4.3.1-Linux-x86_64.sh  -b -p /home/hduser/anaconda2
sudo chown -R hduser:hadoop /home/hduser/anaconda2

# Anaconda variables
sudo sh -c 'echo export PATH=/home/hduser/anaconda2/bin:\$PATH >> /home/hduser/.bashrc'
sudo sh -c 'echo export ANACONDA_PATH=/home/hduser/anaconda2 >> /home/hduser/.bashrc'
sudo sh -c 'echo export PYSPARK_DRIVER_PYTHON=\$ANACONDA_PATH/bin/ipython >> /home/hduser/.bashrc'
sudo sh -c 'echo export PYSPARK_PYTHON=\$ANACONDA_PATH/bin/python >> /home/hduser/.bashrc'
 

