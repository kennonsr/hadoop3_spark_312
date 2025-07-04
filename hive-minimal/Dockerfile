# Simplified Hive Container - No Spark, Minimal Hadoop
FROM ubuntu:20.04

LABEL version="hive_minimal_2310"
LABEL description="Minimal Hive setup with PostgreSQL metastore and local filesystem warehouse"

# Hive and Hadoop versions
ENV HIVE_VERSION=2.3.10
ENV HADOOP_VERSION=3.3.4

USER root

# Install system tools
RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y vim sudo curl git htop man unzip \
  nano wget mlocate openssl net-tools sudo openssh-server ssh postgresql-client

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
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Add hadoop and hive users
RUN useradd -m -s /bin/bash hadoop && \
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
    chown hadoop:hadoop -R /home/hadoop/.ssh

# Install minimal Hadoop (only essential libraries for Hive)
RUN wget https://archive.apache.org/dist/hadoop/core/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz && \
    tar -zxf hadoop-$HADOOP_VERSION.tar.gz -C /opt/ && \
    mv /opt/hadoop-$HADOOP_VERSION /opt/hadoop && \
    rm hadoop-$HADOOP_VERSION.tar.gz

# HADOOP ENV setup (minimal)
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV HADOOP_COMMON_HOME=$HADOOP_HOME
ENV HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/share/hadoop/common/lib
ENV PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$PATH

# hadoop-env.sh settings
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HADOOP_HOME=$HADOOP_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
    echo "export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# Install Hive
RUN wget https://archive.apache.org/dist/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz -P /tmp/ && \
    tar -xzf /tmp/apache-hive-$HIVE_VERSION-bin.tar.gz -C /opt/ && \
    mv /opt/apache-hive-$HIVE_VERSION-bin /opt/hive && \
    rm /tmp/apache-hive-$HIVE_VERSION-bin.tar.gz

# Set Hive environment
ENV HIVE_HOME=/opt/hive
ENV HIVE_CONF_DIR=$HIVE_HOME/conf
ENV PATH=$HIVE_HOME/bin:$PATH

# Install PostgreSQL JDBC driver and Azure ADLS dependencies
RUN apt-get update && \
    apt-get install -y libpostgresql-jdbc-java && \
    cp /usr/share/java/postgresql-jdbc4.jar $HIVE_HOME/lib/ && \
    rm -rf /var/lib/apt/lists/*

# Download Azure ADLS JARs (for future Azure support)
RUN wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-azure/3.3.4/hadoop-azure-3.3.4.jar -P $HIVE_HOME/lib/ && \
    wget https://repo1.maven.org/maven2/com/microsoft/azure/azure-storage/8.6.6/azure-storage-8.6.6.jar -P $HIVE_HOME/lib/ && \
    wget https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-azure-datalake/3.3.4/hadoop-azure-datalake-3.3.4.jar -P $HIVE_HOME/lib/ && \
    wget https://repo1.maven.org/maven2/com/microsoft/azure/azure-data-lake-store-sdk/2.3.9/azure-data-lake-store-sdk-2.3.9.jar -P $HIVE_HOME/lib/

# Configure Hive
RUN echo "export HADOOP_HOME=/opt/hadoop" >> $HIVE_HOME/bin/hive-config.sh && \
    echo "export HIVE_CONF_DIR=$HIVE_HOME/conf" >> $HIVE_HOME/bin/hive-config.sh

# Create directories and set permissions
RUN mkdir -p /opt/hive/warehouse /opt/hive/logs /opt/scripts /tmp/hive /tmp/hive_resources && \
    chmod 777 /opt/hive/warehouse /tmp/hive /tmp/hive_resources && \
    chown -R hadoop:hadoop /opt/hive /opt/hadoop /opt/scripts

# Copy configuration files and startup script
COPY hadoop_config/hive-site-minimal.xml $HIVE_HOME/conf/hive-site.xml
COPY hadoop_config/core-site-minimal.xml $HADOOP_HOME/etc/hadoop/core-site.xml
COPY hive-minimal/scripts/start-hive-services.sh /opt/scripts/
RUN chmod +x /opt/scripts/start-hive-services.sh

# Custom terminal prompt
RUN echo 'PS1="\[$(tput bold)\]\[\033[38;5;193m\]HIVE>>>\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;192m\]\u\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]@\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;117m\]\H\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]:[\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;223m\]\w\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]]:[\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;192m\]\T\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]]\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]{\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;208m\]\$?\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;253m\]}\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]\[\033[38;5;193m\]>>>\[$(tput sgr0)\]\[\033[38;5;15m\]\n\[$(tput bold)\]\[$(tput sgr0)\]\[\033[38;5;9m\]\\$\[$(tput sgr0)\]\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"' >> /home/hadoop/.bashrc

# Start SSH service
RUN service ssh start

# Expose ports
EXPOSE 9083 10000

# Default command
CMD ["/opt/scripts/start-hive-services.sh"]