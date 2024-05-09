#!/bin/bash

# Ensure the non-root user can write where necessary
touch /var/log/startup.log

# If you need to modify configurations owned by root, you need to adjust this beforehand or run as root
sed -i "s/use_serial_tcp = .*/use_serial_tcp = $USE_SERIAL_TCP/g" /etc/genmon/genmon.conf

# Start the application
/git/genmon/startgenmon.sh start

# Follow the log for outputs
tail -F /var/log/startup.log
