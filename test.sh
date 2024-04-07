#!/bin/bash

# Initialize counters
success_count=0
error_count=0

# Function to download the root hints file
download_root_hints() {
  echo "Downloading the root hints file..."
  if curl -sSL https://www.internic.net/domain/named.root -o unbound/root.hints; then
    echo "Root hints file downloaded to unbound/root.hints"
    ((success_count++))
  else
    echo "Error downloading root hints file"
    ((error_count++))
  fi
  echo "------------------------"
}

# Function to test a root server
test_root_server() {
  server_ip="$1"
  echo "Testing $server_ip..."
  if dig @"$server_ip" . NS +short; then
    echo "Test successful for $server_ip"
    ((success_count++))
  else
    echo "Test failed for $server_ip"
    ((error_count++))
  fi
  echo "------------------------"
}

# Path to the root hints file
root_hints_file="unbound/root.hints"

# Check if the root hints file exists; if not, download it
if [ ! -f "$root_hints_file" ]; then
  download_root_hints
fi

# Read the root hints file and extract server IPs
root_servers_from_file=($(grep -E '^[A-M]\.' "$root_hints_file" | awk '{print $NF}'))

# Test each root server
for server_ip in "${root_servers_from_file[@]}"; do
  test_root_server "$server_ip"
done

# Report the progress
echo "Progress Report:"
echo "Successful operations: $success_count"
echo "Failed operations: $error_count"
