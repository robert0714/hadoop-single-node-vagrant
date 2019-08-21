#!/bin/bash
# ubuntu
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
sudo  apt-get  install -y rsync openjdk-8-jdk  nfs-common portmap
sudo ln -s java-8-openjdk-amd64 /usr/lib/jvm/jdk

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

# Download Hadoop to the vagrant shared directory if it doesn't exist yet
cd /vagrant
if [ ! -f hadoop-2.7.7.tar.gz ]; then
	wget http://apache.osuosl.org/hadoop/common/hadoop-2.7.7/hadoop-2.7.7.tar.gz
fi
# Unpack hadoop and install
sudo tar vxzf hadoop-2.7.7.tar.gz -C /usr/local
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
sudo sh -c 'echo export HADOOP_HDFS_HOME=\$HADOOP_INSTALL >> /home/hduser/.bashrc'
sudo sh -c 'echo export YARN_HOME=\$HADOOP_INSTALL >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_COMMON_LIB_NATIVE_DIR=\$\{HADOOP_INSTALL\}/lib/native >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_OPTS=\"-Djava.library.path=\$HADOOP_INSTALL/lib\" >> /home/hduser/.bashrc'


sudo sh -c 'echo export HADOOP_PREFIX=\$HADOOP_INSTALL >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_CONF_DIR=\$HADOOP_INSTALL/etc/hadoop >> /home/hduser/.bashrc'
sudo sh -c 'echo export HADOOP_YARN_HOME=\$HADOOP_INSTALL >> /home/hduser/.bashrc'

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