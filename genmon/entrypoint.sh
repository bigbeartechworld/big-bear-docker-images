#!/bin/bash

# Ensure the /var/log/startup.log file exists
touch /var/log/startup.log

# Change the environment variable to use serial TCP in the genmon.conf file
sed -i "s/use_serial_tcp = .*/use_serial_tcp = $USE_SERIAL_TCP/g" /etc/genmon/genmon.conf

# Start the application
/git/genmon/startgenmon.sh start

# Follow the log for outputs
tail -F /var/log/startup.log
