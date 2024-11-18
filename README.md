# hadoop3_spark312_hive239

### Hadoop, Spark and Hive Docker standalone for local development

It will use a postgres instance for hive metastore, due more stability than Derby local.

# Build Dockers

### Must be executed in sequence

`docker build -t kennon/hadoop:hadoop_331 .`

`docker build -f ./spark/Dockerfile . -t kennon/hadoop:spark_312`

`docker build -f ./postgres-hms/Dockerfile . -t kennon/hadoop:postgres-hms`

# Run 2 dockers, Hadoop-spark-hive and postgres.

### Haddop3 Network Create to integrate containers connection.

`docker network create --subnet=172.20.0.0/16 hadoop2net`

### Run the containers

`docker run -d --net hadoop2net --ip 172.20.1.4 --hostname psqlhms --add-host master-node:172.20.1.1 --name psqlhms -e POSTGRES_PASSWORD=hive -it kennon/hadoop:postgres-hms`


`docker run  -d --net hadoop2net --ip 172.20.1.1 --hostname master-node --add-host psqlhms:172.20.1.4 -p 50070:50070 -p 8088:8088  -p 7177:7077 -p 8180:8080 -p 18180:18080 -p 4040:4040 --name=master-node  -it kennon/hadoop:spark_312`


# Services Initialization in the masternode as hadoop user

### format hadoop namenode - this will be executed oly one time.

`docker exec -u hadoop -it master-node hdfs namenode -format`

PS: If you excute the namenode format command again it will erase hdfs.

### Script to configure and start services

`docker exec -u hadoop -it master-node bash /home/hadoop/script-init-services.sh`

`docker exec -u hadoop -d master-node hive --service metastore`

`docker exec -u hadoop -d master-node hive --service hiveserver2`

# Entering in the master-node container and check if all services are running.

`docker exec  -it master-node /bin/bash`

Now check the services with jps

`jps`

$ jps
576 SecondaryNameNode
257 NameNode
2193 RunJar
3106 Jps
2104 Worker
1097 NodeManager
2265 RunJar
395 DataNode
1996 Master

## have fun with you Haddop environment for deverlopment and test.