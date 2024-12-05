from os.path import abspath
from faker import Faker

from datetime import datetime

import faker
import random

import json

## CONTAINER 
from pyspark.sql import SparkSession

warehouse_location = abspath('/user/hive')

# SPARK SESSION CREATION
spark = SparkSession \
    .builder.master("spark://master-node:7077") \
    .appName("TASK3") \
    .config("spark.sql.warehouse.dir", warehouse_location) \
    .enableHiveSupport() \
    .getOrCreate()

## FUNCTIONALITY
# Headers
headers = ['PERSONAL_NUMBER_ID',
           'FULL_NAME',
           'BIRTH_DATE',
           'SSN',
           'EVENT_DATE_RECORD',
           'PERSONAL_ADDRESS_STREET',
           'PERSONAL_ADDRESS_CITY',
           'PERSONAL_ADDRESS_STATE',
           'PERSONAL_ADDRESS_COUNTRY',
           'PERSONAL_ADDRESS_ZIP_CODE']

# Predefined
numberOfEntries = 10000
count = 0

# Outputs
ls_ids_used = []
ls_output_for_df = []

while count < numberOfEntries:
    fake = Faker('en_US')

    # GENERATE PERSONAL IDENTIFIER (UID)
    uid = fake.random_number(digits = 5)
    if uid in ls_ids_used:
        continue

    # GENERATE LOCALIZED OUTPUT
    try:
        name                = fake.name()
        birth_date          = fake.date_of_birth()
        ssn                 = fake.ssn()
        # ensure event record exceeds birth date always
        event_date_record   = fake.date_time_between(start_date=birth_date)
        address_street      = fake.street_address()
        address_city        = fake.city()
        address_state       = fake.state()
        address_country     = fake.current_country()
        address_zipcode     = fake.zipcode()
    except Exception as e:
        print('FF')
        continue
    # UPDATES
    count += 1                  # placekeeping
    ls_ids_used.append(uid)     # ID management
    ls_output_for_df.append((uid, name, birth_date.strftime("%d/%m/%Y"), ssn, 
                             event_date_record.strftime("%d/%m/%Y"),
                             address_street, address_city, address_state,
                             address_country, address_zipcode))

# Create Spark DF
# sampleDF = spark.sparkContext.parallelize(ls_output_for_df).toDF(headers)
sampleDF = spark.createDataFrame(ls_output_for_df, headers)
# Create Hive Internal Table
sampleDF.write.mode('overwrite').saveAsTable("PERSONAL_DATA")
# Load Into Spark DataFrame
df_loaded = spark.sql('SELECT * FROM personal_data')
# Convert to Shape Ready for Classic JSON
ls_dict = df_loaded.toPandas().to_dict('records')

# Save JSON
with open('/tmp/personal_data_y', 'w') as jsf:
    jsf.write("[\n")
    for idx, record in enumerate(ls_dict):
        jsf.write(json.dumps(record))  # Write each record as JSON
        if idx < len(ls_dict) - 1:    # Add a comma if it's not the last record
            jsf.write(",\n")
        else:
            jsf.write("\n")  # No comma for the last record
    jsf.write("]\n")  # End the JSON array
# jsf = open('/tmp/personal_data_x', 'w')
# jsf.write(json.dumps(ls_dict))
jsf.close()

#df_loaded.coalesce(1).write.json("/tmp/personal_data_3")
#df_loaded.coalesce(1).write.options(header = True).json("/tmp/personal_data_1")


