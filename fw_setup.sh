#!/usr/bin/env bash


#############################################
# STEP 1: Clear all old rules
#############################################


# Flush (-F) all chain rules
sudo /sbin/iptables -F
# Flush chain rules for mangle table - includes PREROUTING, OUTPUT, INPUT, FORWARD, and POSTROUTING
sudo /sbin/iptables -F -t mangle
# Flush chain rules for NAT table - includes locally generated packets (PREROUTING, INPUT, OUTPUT, and POSTROUTING)
sudo /sbin/iptables -F -t nat

# Delete (-X) all chain rules 
sudo /sbin/iptables -X 
# Delete chain rules for mangle table - includes PREROUTING, OUTPUT, INPUT, FORWARD, and POSTROUTING
sudo /sbin/iptables -X -t mangle
# Delete chain rules for NAT table - includes locally generated packets (PREROUTING, INPUT, OUTPUT, and POSTROUTING)
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


#######################
# INPUT chain
#######################


# Allow established and related incoming traffic (stateful)
# This allows return traffic to outgoing connections that were initiated by this server
sudo /sbin/iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Accept (incoming) local traffic
sudo /sbin/iptables -A INPUT -i lo -j ACCEPT

# Allow incoming SSH in a stateful manner only from the provided IP address
sudo /sbin/iptables -A INPUT -p tcp --dport 22 -s 12.34.56.78 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Drop invalid incoming packets
sudo /sbin/iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# Allow all incoming HTTPS connections (stateful)
sudo /sbin/iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Allow all incoming HTTP connections (stateful)
sudo /sbin/iptables -A INPUT -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

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


# Output traffic from established connections is ok
sudo iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Accept loopback output
sudo /sbin/iptables -A OUTPUT -o lo -j ACCEPT

# Allow outgoing SSH in a stateful manner
# This rule should relate only to SSH with the provided IP (above)
sudo /sbin/iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Allow all outgoing HTTPS connections if an established connection has been made (stateful)
sudo /sbin/iptables -A OUTPUT -p tcp --sport 443 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Allow all outgoing HTTP connections if an established connection has been made (stateful)
sudo /sbin/iptables -A OUTPUT -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Allow new and established outgoing HTTP connections (stateful)
# This permits traffic such as apt-get queries
sudo /sbin/iptables -A OUTPUT -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Allow DNS out on port 53
# This is needed for domain resolution on apt-get queries
sudo /sbin/iptables -A OUTPUT -p udp --dport domain -j ACCEPT

# Catch-all to reject anything not matching the above rules
sudo /sbin/iptables -A OUTPUT -j REJECT


#############################################
# STEP 4: Save the rules we just created
#############################################


# iptables-save dumps the iptables config to the screen, so redirect it to the rules file
sudo bash -c "/sbin/iptables-save > /etc/iptables.rules"

# Create a variable containing the text we'll dump into the restore script
read -r -d '' RESTORE << EOM
#!/bin/bash
/sbin/iptables-restore < /etc/iptables.rules
EOM

# Restore the configuration on startup
sudo bash -c "echo \"$RESTORE\" > /etc/network/if-pre-up.d/firewall"
sudo chmod +x /etc/network/if-pre-up.d/firewall
