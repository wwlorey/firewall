#!/usr/bin/env bash

# Write your IPtables configuration script here, 
# including comments describing in detail what 
# each componend of each command on every line does.

# Note: /sbin/ is not in the path so we must prepend /sbin/ to the iptables commands

# Set port 80 as open for TCP traffic
sudo /sbin/iptables -A INPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT

# Set port 443 AS open for TCP traffic
sudo /sbin/iptables -A INPUT -m state --state NEW -p tcp --dport 443 -j ACCEPT

# Save the rules we just created
sudo /sbin/iptables-save

