#!/usr/bin/env bash

# Write your IPtables configuration script here, 
# including comments describing in detail what 
# each componend of each command on every line does.


# NOTE: /sbin/ is not in the path so we must prepend /sbin/ to the iptables commands


#############################################
# STEP 1: Clear all old rules
#############################################

# Flush iptables (-F)
sudo /sbin/iptables -F
# Flush mangle table - includes PREROUTING, OUTPUT, INPUT, FORWARD, and POSTROUTING
sudo /sbin/iptables -F -t mangle
# Flush NAT table - includes locally generated packets (PREROUTING, INPUT, OUTPUT, and POSTROUTING)
sudo /sbin/iptables -F -t nat

# Delete chain for iptables (-X)
sudo /sbin/iptables -X 
# Delete chain for mangle table - includes PREROUTING, OUTPUT, INPUT, FORWARD, and POSTROUTING
sudo /sbin/iptables -X -t mangle
# Delete chain for NAT table - includes locally generated packets (PREROUTING, INPUT, OUTPUT, and POSTROUTING)
sudo /sbin/iptables -X -t nat


#############################################
# STEP 2: Set default policies for each chain
#############################################

# NOTE: -P means policy
# Default to DROP all inputs
sudo /sbin/iptables -P INPUT DROP
# Default to DROP all forwards
sudo /sbin/iptables -P FORWARD DROP
# Default to DROP all outputs
sudo /sbin/iptables -P OUTPUT DROP


#############################################
# STEP 3: Add new rules to each chain 
#         (INPUT, FORWARD, OUTPUT)
#############################################

# sudo iptables -A  -i <interface> -p <protocol (tcp/udp) > -s <source> --dport <port no.>  -j <target>

#######################
# INPUT chain
#######################

# Allow established and related incoming traffic (stateful)
# This allows return traffic to outgoing connections that were initiated by this server
sudo /sbin/iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Accept local traffic
sudo /sbin/iptables -A INPUT -i lo -j ACCEPT

# Allow incoming SSH in a stateful manner only from the provided IP address
sudo /sbin/iptables -A INPUT -p tcp -s 12.34.56.78 --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Drop invalid packets
sudo /sbin/iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Allow all incoming HTTPS connections
sudo /sbin/iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
sudo /sbin/iptables -A OUTPUT -p tcp --sport 443 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Allow all incoming HTTP connections
sudo /sbin/iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
sudo /sbin/iptables -A OUTPUT -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Catch-all to reject anything not matching the above rules
sudo /sbin/iptables -A INPUT -j REJECT


#######################
# FORWARD CHAIN
#######################

# Assume no forwarding is required
# Reject all forwards
sudo /sbin/iptables -A FORWARD -j REJECT


#######################
# OUTPUT CHAIN
#######################

# Accept loopback output
sudo /sbin/iptables -A OUTPUT -o lo -j ACCEPT

# HTTPS port allowed out
sudo /sbin/iptables -A OUTPUT -p tcp --dport https -j ACCEPT

# HTTP port allowed out
sudo /sbin/iptables -A OUTPUT -p tcp --dport http -j ACCEPT

# DNS allowed out on 53
sudo /sbin/iptables -A OUTPUT -p udp --dport domain -j ACCEPT

# Catch-all to reject anything not matching the above rules
sudo /sbin/iptables -A OUTPUT -j REJECT


#############################################
# STEP 4: Save the rules we just created
#############################################

# iptables-save dumps the iptables config to the screen, so redirect it to the rules file
sudo bash -c "/sbin/iptables-save > /etc/iptables.rules"

read -r -d '' RESTORE << EOM
#!/bin/bash
/sbin/iptables-restore < /etc/iptables.rules
EOM

# Restore the configuration on startup
sudo bash -c "echo \"$RESTORE\" > /etc/network/if-pre-up.d/firewall"
sudo chmod +x /etc/network/if-pre-up.d/firewall
