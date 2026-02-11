#!/bin/bash
set -e

# Ensure the /var/log/startup.log file exists
touch /var/log/startup.log

# Ensure the /git/genmon directory exists and has the necessary files
if [ ! -f /git/genmon/startgenmon.sh ]; then
  echo "Populating /git/genmon..."
  git clone --depth 1 https://github.com/jgyates/genmon.git /git/genmon
  chmod 775 /git/genmon/startgenmon.sh /git/genmon/genmonmaint.sh
  rm -rf /git/genmon/.git
fi

# Wait for the /git/genmon/startgenmon.sh to exist
while [ ! -f /git/genmon/startgenmon.sh ]; do
  echo "Waiting for /git/genmon/startgenmon.sh to be available..."
  sleep 1
done

# Ensure the /etc/genmon directory exists and has the necessary configuration files
if [ ! -f /etc/genmon/genmon.conf ]; then
  echo "Creating default configuration in /etc/genmon..."
  mkdir -p /etc/genmon
  if [ -f /git/genmon/conf/genmon.conf ]; then
    cp /git/genmon/conf/genmon.conf /etc/genmon/genmon.conf
  else
    echo "Warning: /git/genmon/conf/genmon.conf does not exist."
    cat <<EOL > /etc/genmon/genmon.conf
# Default genmon configuration
use_serial_tcp = $USE_SERIAL_TCP
EOL
  fi
fi

# Change the environment variable to use serial TCP in the genmon.conf file
sed -i "s/use_serial_tcp = .*/use_serial_tcp = $USE_SERIAL_TCP/g" /etc/genmon/genmon.conf

# Start the application
/git/genmon/startgenmon.sh start

# If a command was provided, execute it instead of tailing logs
if [ $# -gt 0 ]; then
    exec "$@"
else
    # Follow the log for outputs (normal production mode)
    tail -F /var/log/startup.log
fi
