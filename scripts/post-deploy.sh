#!/bin/bash
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
" >> /etc/hosts
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
