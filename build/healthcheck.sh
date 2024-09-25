#!/bin/bash

# Health check script for Docker container

# Get the public IP address of the container
CURRENT_IP=$(wget -qO- ifconfig.me/ip)


if [ -z "${CURRENT_IP+x}" ]; then
    echo "CURRENT_IP is either undefined or empty. Exiting the script."
    exit 1  # Exit with a non-zero status to indicate failure
fi

# Get the expected IP address from the environment variable XIP
EXPECTED_IP="${XIP}"

# Check if CURRENT_IP and EXPECTED_IP are the same
if [ "$CURRENT_IP" == "$EXPECTED_IP" ]; then
    echo "Health Check Failed: Current IP ($CURRENT_IP) matches expected IP ($EXPECTED_IP)"
    exit 1  # Exit with a non-zero status to indicate failure
else
    echo "Health Check Passed: Current IP ($CURRENT_IP) does not match expected IP ($EXPECTED_IP)"
    exit 0  # Exit with a zero status to indicate success
fi
