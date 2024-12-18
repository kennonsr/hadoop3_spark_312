FROM kennon/hadoop:hadoop_331 
LABEL version="Spark_312_standalone_with_hadoop"
USER root

# installing python 3.11 for Pyspark

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive add-apt-repository --yes ppa:deadsnakes/ppa && \
    apt-get install -y python3.10 python3.10-distutils
RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

ENV SCALA_VERSION 2.12.12
ENV SPARK_VERSION 3.1.2

# get sources

#SCALA Source
RUN mkdir /usr/share/scala && \
    wget https://downloads.lightbend.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz -P /tmp/ && \
    tar -xzf /tmp/scala-$SCALA_VERSION.tgz -C /tmp/ && \
    mv /tmp/scala-$SCALA_VERSION/* /usr/share/scala/ && \
    rm -rf /tmp/scala-$SCALA_VERSION /tmp/scala-$SCALA_VERSION.tgz && \
    cp /usr/share/scala/bin/* /usr/bin/

# hadoop pre built package
RUN wget https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop3.2.tgz -P /usr/local/hadoop/ && \
    tar -xzf /usr/local/hadoop/spark-$SPARK_VERSION-bin-hadoop3.2.tgz -C /usr/local/hadoop/ && \
    mv /usr/local/hadoop/spark-$SPARK_VERSION-bin-hadoop3.2 /usr/local/hadoop/spark && \
    rm /usr/local/hadoop/spark-$SPARK_VERSION-bin-hadoop3.2.tgz
# RUN wget https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.19/postgresql-42.2.19.jar -p /usr/local/hadoop/spark/jars/

RUN mkdir -p /usr/local/hadoop/spark/logs
RUN chown hadoop -R /usr/local/hadoop/spark/logs

# set environment variables
ENV SCALA_HOME /usr/share/scala
ENV SPARK_HOME /usr/local/hadoop/spark
ENV SPARK_LOG_DIR /usr/local/hadoop/spark/logs
ENV HADOOP_HOME /usr/local/hadoop
ENV SPARK_DIST_CLASSPATH $(hadoop classpath)
ENV PATH $SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH
ENV PATH $SCALA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH /usr/local/hadoop/hadoop/share/hadoop/common/lib:$LD_LIBRARY_PATH

# Configure Spark environment
RUN mv /usr/local/hadoop/spark/conf/spark-env.sh.template /usr/local/hadoop/spark/conf/spark-env.sh && \
    echo "export SPARK_DIST_CLASSPATH=$(hadoop classpath)" >> /usr/local/hadoop/spark/conf/spark-env.sh && \
    echo "export SPARK_LOG_DIR=/usr/local/hadoop/spark/logs" >> /usr/local/hadoop/spark/conf/spark-env.sh && \
    echo "export PYSPARK_PYTHON=python3.10" >> /usr/local/hadoop/spark/conf/spark-env.sh && \
    mv /usr/local/hadoop/spark/conf/spark-defaults.conf.template /usr/local/hadoop/spark/conf/spark-defaults.conf && \
    echo "spark.eventLog.dir file:/usr/local/hadoop/spark/logs" >> /usr/local/hadoop/spark/conf/spark-defaults.conf && \
    echo "spark.history.fs.logDirectory file:/usr/local/hadoop/spark/logs" >> /usr/local/hadoop/spark/conf/spark-defaults.conf && \
    echo "spark.master spark://master-node:7077" >> /usr/local/hadoop/spark/conf/spark-defaults.conf && \
    echo "spark.sql.catalogImplementation hive" >> /usr/local/hadoop/spark/conf/spark-defaults.conf && \
    echo "spark.yarn.jars hdfs://master-node:8020/spark-jars/*" >> /usr/local/hadoop/spark/conf/spark-defaults.conf
    #RUN echo "spark.sql.hive.metastore.version 2.3.0" >> /usr/local/hadoop/spark/conf/spark-defaults.conf && \
    #RUN echo "spark.sql.hive.metastore.jars $(hadoop classpath)" >> /usr/local/hadoop/spark/conf/spark-defaults.conf

# Copy configuration files
ADD hadoop_config/hbase-site.xml /usr/local/hadoop/spark/conf/
ADD hadoop_config/hive-site.xml /usr/local/hadoop/spark/conf/
ADD hadoop_config/core-site.xml /usr/local/hadoop/spark/conf/
ADD hadoop_config/hdfs-site.xml /usr/local/hadoop/spark/conf/
ADD hadoop_config/yarn-site.xml /usr/local/hadoop/spark/conf/
#ADD hadoop_config/workers /usr/local/hadoop/spark/conf/slaves

# Set ownership
RUN chown hadoop -R /usr/local/hadoop/spark


ENV SPARK_MASTER_PORT=7077 \
SPARK_MASTER_WEBUI_PORT=8080 \
SPARK_WORKER_WEBUI_PORT=8080 \
SPARK_WORKER_PORT=7000 \
SPARK_WORKLOAD="master"

# Hive 2.3.9 Intallation

ENV HIVE_VERSION 2.3.9

# get sources
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y libpostgresql-jdbc-java && \
    wget https://archive.apache.org/dist/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz -P /usr/local/hadoop/
RUN tar -xzf /usr/local/hadoop/apache-hive-$HIVE_VERSION-bin.tar.gz -C /usr/local/hadoop/
RUN mv /usr/local/hadoop/apache-hive-$HIVE_VERSION-bin /usr/local/hadoop/hive
RUN rm -rf /usr/local/hadoop/apache-hive-$HIVE_VERSION*

# set Hive environment variables
ENV HIVE_HOME /usr/local/hadoop/hive
ENV PATH $HIVE_HOME/bin:$PATH

RUN cp /usr/share/java/postgresql-jdbc4.jar /usr/local/hadoop/hive/lib/
ADD hadoop_config/hive-site.xml $HIVE_HOME/conf/hive-site.xml
RUN echo "export HADOOP_HOME=/usr/local/hadoop" >> /usr/local/hadoop/hive/bin/hive-config.sh
RUN mkdir -p $HIVE_HOME/hcatalog/var/log
RUN mkdir -p $HIVE_HOME/var/log
RUN chown hadoop -R /usr/local/hadoop/hive
RUN export LANGUAGE=en_US.UTF-8
ENV HIVE_CONF_DIR $HIVE_HOME/conf

EXPOSE 8080 7077 9000 6066 4040 18080 8042 10000

COPY hadoop_config/spark-entrypoint.sh /usr/local/bin/spark-entrypoint.sh

# RUN chmod +x /usr/local/bin/spark-entrypoint.sh

# ENTRYPOINT ["/usr/local/bin/spark-entrypoint.sh"]
