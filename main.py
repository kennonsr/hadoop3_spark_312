from os.path import abspath
from pyspark.sql import SparkSession

#enableHiveSupport()

warehouse_location = abspath('/user/hive')

spark = SparkSession \
    .builder.master("spark://master-node:7077") \
    .appName("SS") \
    .config("spark.sql.warehouse.dir", warehouse_location) \
    .enableHiveSupport() \
    .getOrCreate()

# spark = SparkSession.builder.appName("Testing PySpark Example").getOrCreate()
# print('venv')

df = spark.sql("SELECT driverid, name, SUM(hours) AS total_hours, sum(MILES) AS total_miles FROM drivers \
               LEFT JOIN timesheet ON drivers.driverid = timesheet.id \
               WHERE driverid IS NOT NULL\
               GROUP BY driverid, name \
               ORDER BY driverid")
df.show() 
df.coalesce(1).write.options(lineSep = '\n', header = True).csv("/tmp/meet6")

# id, name, SUM(hours), SUM(miles)
