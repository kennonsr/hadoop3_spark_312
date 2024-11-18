# Hadoop Services
echo ">> Hadoop Services ..."
start-dfs.sh
sleep 5
start-yarn.sh
sleep 5
mr-jobhistory-daemon.sh start historyserver
sleep 5

# HDFS Directories Preparation
echo ">> HDFS Directories Preparation ..."
hdfs dfs -mkdir -p /tmp
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -mkdir -p /user/hive/metastore
hdfs dfs -chmod g+w /tmp
hdfs dfs -chmod g+w /user/hive/warehouse
hdfs dfs -chmod g+w /user/hive/metastore
hdfs dfs -mkdir -p /spark-jars
hdfs dfs -mkdir -p /log/spark
hdfs dfs -chmod g+w /spark-jars
hdfs dfs -chmod g+w /log/spark
hdfs dfs -mkdir -p /user/hbase
hdfs dfs -mkdir -p /hbase
hdfs dfs -chmod g+w /hbase
hdfs dfs -chmod g+w /user/hbase

# Spark Services Master and Worker Standalone
echo ">> Spark start ..."
start-all.sh



# # Hive Metastore Server and Hiveserver2
# echo ">> Starting Hive Metastore ..."
# hive --service metastore
# sleep 5
# hive --service hiveserver2




