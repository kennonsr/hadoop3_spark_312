#!/bin/bash

# Start Spark master
start-master.sh &
# Wait for Spark master to be ready
sleep 5
# Start Spark workers
start-worker.sh spark://$(hostname):7077 &
tail -f /dev/null
