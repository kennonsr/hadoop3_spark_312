# hadoop3_spark_312

Docker for standalone and pseudo-distributed mode

# Build and run Hadoop Docker

`docker build -t kennon/hadoop_331:hadoop_331 .`

`docker run -t -i -d -p 51070:50070 -p 4040:4040 -p 8088:8088  -p 7077:7077 -p 8080:8080 -p 18080:18080 -p 4140:4040 --name=hadoop_331 --hostname=master-node spark_312_hadoop331`

`docker exec -it hadoop_331 /bin/bash`

# Build sparl 312 on top of the previous hadoop 331 build.

`docker build -f ./spark/Dockerfile . -t kennon/hadoop_331:spark_312`

# Inside of docker container

`hdfs namenode -format`

`start-dfs.sh`

`start-yarn.sh`

`hdfs dfs -mkdir -p /user/root`

`start-all.sh` 

`sleep 5`


`schematool -initSchema -dbType derby`

`hive --service metastore`

`hiveserver2`

`beeline -u jdbc:hive2://master-node:10000`

hdfs namenode -format
start-dfs.sh
start-yarn.sh

hdfs dfs -mkdir -p /tmp
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chmod g+w /tmp
hdfs dfs -chmod g+w /user/hive/warehouse