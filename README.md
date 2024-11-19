
# Hadoop 3.3.1, Spark 3.1.2, Hive 2.3.9 Docker Environment

### A standalone Docker setup for local development with Hadoop, Spark, and Hive.

This setup uses a PostgreSQL instance as the Hive Metastore for greater stability compared to the default Derby database.

---

## Table of Contents

1. [Building Docker Images](#building-docker-images)
2. [Running Containers](#running-containers)
   - [Create a Docker Network](#step-1-create-a-docker-network)
   - [Run Containers](#step-2-run-containers)
3. [Initializing Services on `master-node`](#initializing-services-on-master-node)
   - [Format the Hadoop Namenode](#step-1-format-the-hadoop-namenode)
   - [Start Services](#step-2-start-services)
4. [Verifying Services](#verifying-services)
   - [Enter the `master-node` Container](#step-1-enter-the-master-node-container)
   - [Check Running Services](#step-2-check-running-services-with-jps)
5. [Notes](#notes)
6. [Conclusion](#conclusion)

---

## Building Docker Images

Follow the sequence below to build the Docker images:

1. **Build the Hadoop image - x86/AMD64 or ARM (Apple M-series and Raspberry):**  
    Please, in this first step only execute one of the commands that is related to your hardware/processor, generally Windows machines uses AMD / Intel / x86.

   `AMD64 / INTEL64 Processors`
   ```bash
   docker build -t kennon/hadoop:hadoop_331 .
   ```
   or

   `ARM Processors - Apple M1, M2, M3`
   ```bash
   docker build -f ./hadoop_arm64/Dockerfile -t kennon/hadoop:hadoop_331 .
   ```

2. **Build the Spark image:**
   ```bash
   docker build -f ./spark/Dockerfile -t kennon/hadoop:spark_312 .
   ```

3. **Build the PostgreSQL Hive Metastore image:**
   ```bash
   docker build -f ./postgres-hms/Dockerfile -t kennon/hadoop:postgres-hms .
   ```

---

## Running Containers you have 2 options, individual steps or via docker compose:

---
## Option 1: Running the following steps individually

### Step 1: Create a Docker Network
To enable communication between containers, create a network:
```bash
docker network create --subnet=172.20.0.0/16 hadoop2net
```

### Step 2: Run Containers
1. **Start the PostgreSQL Hive Metastore container:**
   ```bash
   docker run -d \
     --net hadoop2net \
     --ip 172.20.1.4 \
     --hostname psqlhms \
     --add-host master-node:172.20.1.1 \
     --name psqlhms \
     -e POSTGRES_PASSWORD=hive \
     -it kennon/hadoop:postgres-hms
   ```

2. **Start the Hadoop-Spark-Hive container:**
   ```bash
   docker run -d \
     --net hadoop2net \
     --ip 172.20.1.1 \
     --hostname master-node \
     --add-host psqlhms:172.20.1.4 \
     -p 50070:50070 \
     -p 8088:8088 \
     -p 7177:7077 \
     -p 8180:8080 \
     -p 18180:18080 \
     -p 4040:4040 \
     --name=master-node \
     -it kennon/hadoop:spark_312
   ```
## Option 2: Using docker compose

### DOCKER COMPOSE Step
1. **Start containers vis docker-compose:**
```bash
docker-compose up -d
```
---

## Initializing Services on `master-node`

### Step 1: Format the Hadoop Namenode
**Note:** This step needs to be executed only once. Running it again will erase the HDFS data.
```bash
docker exec -u hadoop -it master-node hdfs namenode -format
```

### Step 2: Start Services
Run the following commands to configure and start Hadoop, Spark, and Hive services:

1. **Initialize services:**
   ```bash
   docker exec -u hadoop -it master-node bash /home/hadoop/script-init-services.sh
   ```

2. **Start the Hive Metastore service:**
   ```bash
   docker exec -u hadoop -d master-node hive --service metastore
   ```

3. **Start the HiveServer2 service:**
   ```bash
   docker exec -u hadoop -d master-node hive --service hiveserver2
   ```

---

## Verifying Services

### Step 1: Enter the `master-node` container:
```bash
docker exec -it master-node /bin/bash
```

### Step 2: Check running services with `jps`:
Run the `jps` command to confirm all services are active:
```bash
jps
```

Sample output:
```
576 SecondaryNameNode
257 NameNode
2193 RunJar
3106 Jps
2104 Worker
1097 NodeManager
2265 RunJar
395 DataNode
1996 Master
```

---

## Notes

- **Network and IPs:** Ensure that the IP addresses (`172.20.x.x`) are not already in use. Adjust as necessary for your local environment.
- **PostgreSQL Password:** The default password for the PostgreSQL Hive Metastore is set to `hive`. You can modify this in the `docker run` command as needed.
- **Test Script:** Inside of the folder [test_script](./test_script/) you find instructions to test reading [cluster_simple_test.md](./test_script/cluster_simple_test.md) .

---

## Conclusion

Enjoy your Hadoop environment for development and testing. If you encounter any issues, revisit the steps or consult the logs for troubleshooting.

Happy coding! 🚀
