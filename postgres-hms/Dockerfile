FROM postgres:13-alpine

USER root

RUN export LANGUAGE=en_US.UTF-8
ADD hadoop_config/hive-schema-2.3.0.postgres.sql /hive/hive-schema-2.3.0.postgres.sql
ADD hadoop_config/hive-txn-schema-2.3.0.postgres.sql /hive/hive-txn-schema-2.3.0.postgres.sql
COPY hadoop_config/init-hive-db.sh /docker-entrypoint-initdb.d/init-user-db.sh
