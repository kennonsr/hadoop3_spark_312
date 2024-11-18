## Simple Test on the Cluster to Verify Functionality

### **Tests with Hive**

1. **Copy the test file to the master-node container:**
   ```bash
   docker cp ./test_script/test_data.csv master-node:/tmp/
   ```

2. **Access the master-node container:**
   ```bash
   docker exec -u hadoop -it master-node /bin/bash
   ```

3. **Create a directory in HDFS:**
   ```bash
   hdfs dfs -mkdir -p /user/hadoop/test
   ```

4. **Upload the test file to HDFS:**
   ```bash
   hdfs dfs -put /tmp/test_data.csv /user/hadoop/test/
   ```

5. **Launch Hive:**
   ```bash
   beeline -u "jdbc:hive2://master-node:10000/"
   ```
   *Alternatively:*
   ```bash
   hive
   ```

6. **Create a schema in Hive:**
   ```sql
   create schema if not exists test;
   ```

7. **Create an external table in Hive:**
   ```sql
   create external table if not exists test.test_data (
       row1 int,
       row2 int,
       row3 decimal(10,3),
       row4 int
   )
   row format delimited
   fields terminated by ','
   stored as textfile
   location 'hdfs://master-node:8020/user/hadoop/test/';
   ```

8. **Query the table:**
   ```sql
   select * from test.test_data where row3 > 2.499;
   ```

   **Sample Results:**
   ```
   OK
   1   122   5.000   838985046
   1   185   4.500   838983525
   1   231   4.000   838983392
   1   292   3.500   838983421
   1   316   3.000   838983392
   1   329   2.500   838983392
   1   377   3.500   838983834
   1   420   5.000   838983834
   1   466   4.000   838984679
   1   480   5.000   838983653
   1   520   2.500   838984679
   1   539   5.000   838984068
   1   586   3.500   838984068
   1   588   5.000   838983339
   Time taken: 0.175 seconds, Fetched: 14 row(s)
   ```

---

### **Testing Spark Hive Integration**

#### **Spark-shell on master-node or Edge Node (Spark > 2.4.x)**

1. **Launch Spark-shell:**
   ```bash
   spark-shell --driver-java-options "-Dhive.metastore.uris=thrift://master-node:9083"
   ```

2. **Run the following Scala code:**
   ```scala
   import org.apache.spark.sql.SparkSession

   val spark = SparkSession.builder()
       .master("spark://master-node:7077")
       .appName("kennon.test.nl")
       .config("spark.sql.warehouse.dir", "/users/hive/warehouse")
       .enableHiveSupport()
       .getOrCreate()

   val df = sql("select * from test.test_data limit 10")
   df.show()
   ```

---

### **Testing HBase with PyBase**

1. **Copy the test Python script to the Master-node Node:**
   ```bash
   docker cp ./test_script/py-base-test-2.py master-node:/tmp/
   ```

2. **Run the test script using Python 3 inside of master-node container:**
   ```bash
   python3 /tmp/py-base-test-2.py
   ```