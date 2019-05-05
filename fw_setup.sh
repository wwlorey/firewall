#!/usr/bin/env bash

# Write your IPtables configuration script here, 
# including comments describing in detail what 
# each componend of each command on every line does.

# Set port 80 as open for TCP traffic
/sbin/iptables -A INPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT

# Set port 443 AS open for TCP traffic
/sbin/iptables -A INPUT -m state --state NEW -p tcp --dport 443 -j ACCEPT

# Save the rules we just created
iptables-save

