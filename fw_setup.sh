#!/usr/bin/env bash

# Write your IPtables configuration script here, 
# including comments describing in detail what 
# each componend of each command on every line does.

# Note: /sbin/ is not in the path so we must prepend /sbin/ to the iptables commands

# Set port 80 as open for TCP traffic
sudo /sbin/iptables -A INPUT -m state --state NEW -p tcp --dport 80 -j ACCEPT

# Set port 443 AS open for TCP traffic
sudo /sbin/iptables -A INPUT -m state --state NEW -p tcp --dport 443 -j ACCEPT

# Setup SSH
sudo /sbin/iptables -A INPUT -p tcp -s 12.34.56.78 --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Save the rules we just created
# iptables-save dumps the iptables config to the screen, so redirect it to the rules file
sudo bash -c "/sbin/iptables-save > /etc/iptables.rules"

read -r -d '' RESTORE << EOM
#!/bin/bash
/sbin/iptables-restore < /etc/iptables.rules
EOM

# Restore the configuration on startup
sudo bash -c "echo \"$RESTORE\" > /etc/network/if-pre-up.d/firewall"
sudo chmod +x /etc/network/if-pre-up.d/firewall

