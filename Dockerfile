#Build a pseudo distributed and standalone Hadoop version 3.3.1

FROM ubuntu:20.04

# MAINTAINER Kennon 
LABEL version="hadoop_331_standalone"
# Hadoop Version
ENV HADOOP_VERSION 3.3.1

USER root

# Install system tools

RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y vim sudo curl git htop man unzip \
  nano wget mlocate openssl net-tools sudo openssh-server ssh

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata && \
  cp /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime && \
  echo "Europe/Amsterdam" >  /etc/timezone && \
  rm -rf /var/lib/apt/lists/*

# Install Java - OpenJDK8

RUN \
  apt-get update && \
  apt-get install -y openjdk-8-jdk && \
  rm -rf /var/lib/apt/lists/* && \
  Javadir=$(dirname $(dirname $(readlink -f $(which javac)))) && \
  java -version
ENV JAVA_HOME $Javadir

# Add hadoop, hdfs, and yarn users, set up SSH passwordless login, and configure SSH
RUN useradd -m -s /bin/bash hadoop && \
    useradd -rm hdfs && \
    useradd -m -s /bin/bash yarn && \
    ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa && \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys && \
    echo "PubkeyAuthentication yes" >> /etc/ssh/ssh_config && \
    mkdir -p /home/hadoop/.ssh && \
    echo "PubkeyAcceptedKeyTypes +ssh-dss" >> /home/hadoop/.ssh/config && \
    echo "PasswordAuthentication no" >> /home/hadoop/.ssh/config && \
    cp /root/.ssh/id_rsa.pub /home/hadoop/.ssh/id_rsa.pub && \
    cp /root/.ssh/id_rsa /home/hadoop/.ssh/id_rsa && \
    chmod 400 /home/hadoop/.ssh/id_rsa /home/hadoop/.ssh/id_rsa.pub && \
    cat /home/hadoop/.ssh/id_rsa.pub >> /home/hadoop/.ssh/authorized_keys && \
    chown hadoop:hadoop -R /home/hadoop/.ssh && \
    usermod -aG hadoop yarn && \
    su - yarn -c "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa" && \
    su - yarn -c "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys" && \
    su - yarn -c "chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"

# Hadoop sources and setup

RUN wget https://archive.apache.org/dist/hadoop/core/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz && \
    tar -zxf hadoop-$HADOOP_VERSION.tar.gz -C /usr/local/ && \
    rm hadoop-$HADOOP_VERSION.tar.gz && \
    ln -s /usr/local/hadoop-$HADOOP_VERSION /usr/local/hadoop && \
    systemctl enable ssh

# HADOOP ENV setup
ENV HADOOP_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR $HADOOP_HOME/etc/hadoop
ENV HADOOP_MAPRED_HOME $HADOOP_HOME
ENV HADOOP_COMMON_HOME $HADOOP_HOME
ENV HADOOP_HDFS_HOME $HADOOP_HOME
ENV HADOOP_COMMON_LIB_NATIVE_DIR $HADOOP_HOME/share/hadoop/common/lib
ENV YARN_HOME $HADOOP_HOME
ENV PATH $JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

# hadoop-env.sh and profile settings
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HADOOP_HOME=$HADOOP_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_NAMENODE_USER=hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_DATANODE_USER=hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HDFS_SECONDARYNAMENODE_USER=hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export YARN_RESOURCEMANAGER_USER=hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export YARN_NODEMANAGER_USER=hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HADOOP_HOME=$HADOOP_HOME" >> /etc/profile.d/hadoop.sh && \
    echo "export PATH=$HADOOP_HOME/bin:$PATH" >> /etc/profile.d/hadoop.sh && \
    chown hadoop:hadoop /etc/profile.d/hadoop.sh

# PSEUDO / STANDALONE HADOOP DISTRIBUTED MODE CONF

ADD hadoop_config/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
ADD hadoop_config/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
ADD hadoop_config/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml
ADD hadoop_config/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml

#ADD hadoop_config/slaves $HADOOP_HOME/etc/hadoop/slaves
#
ADD hadoop_config/ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config
ADD hadoop_config/bootstrap.sh /usr/local/bootstrap.sh
RUN chown root:root /usr/local/bootstrap.sh
RUN chmod 700 /usr/local/bootstrap.sh


#custom TERM
RUN echo 'PS1="\[$(tput bold)\]\[\033[38;5;193m\]>>>\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;192m\]\u\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]@\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;117m\]\H\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]:[\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;223m\]\w\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]]:[\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;192m\]\T\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]]\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]{\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;208m\]\$?\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]}\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;193m\]>>>\[$(tput sgr0)\]\[\033[38;5;15m\]\n\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;9m\]\\$\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"' >> /home/hadoop/.bashrc && \
    echo 'PS1="\[$(tput bold)\]\[\033[38;5;193m\]>>>\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;192m\]\u\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]@\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;117m\]\H\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]:[\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;223m\]\w\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]]:[\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;192m\]\T\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]]\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]{\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;208m\]\$?\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]}\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;193m\]>>>\[$(tput sgr0)\]\[\033[38;5;15m\]\n\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;9m\]\\$\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"' >> ~/.bashrc


ENV BOOTSTRAP /usr/local/bootstrap.sh
RUN service ssh start
RUN mkdir -p /hadoop/data/01
RUN chmod 777 -R /hadoop/data/01*
RUN chown hadoop -R /usr/local/hadoop
#
CMD ["/usr/local/bootstrap.sh", "-d"]

# # Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000
# # Mapred ports
EXPOSE 10020 19888
# #Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
# SSH
EXPOSE 22
