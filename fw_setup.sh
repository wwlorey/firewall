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


# Provided code
# TODO: adapt for assignment

# STEP 0: clear all old rultes
sudo iptables -F # (--flush or -F)
sudo iptables -F -t mangle
sudo iptables -F -t nat

sudo iptables -X # (--delete-chain or -X)
sudo iptables -X -t mangle
sudo iptables -X -t nat


# STEP 1: set default policies for each chain, using (--policy or -P)
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT DROP


# STEP 2: Add new rules to each chain (INPUT, FORWARD, OUTPUT) using this syntax:

# sudo iptables -A  -i <interface> -p <protocol (tcp/udp) > -s <source> --dport <port no.>  -j <target>


##########INPUT CHAIN

# As network traffic generally needs to be two-way, incoming and outgoing to work properly, it is typical to create a firewall rule that allows established and related incoming traffic, so that the server will allow return traffic to outgoing connections initiated by the server itself. This command will allow that:
#old syntax: sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate RELATED, ESTABLISHED -j ACCEPT

# Local traffic accepted
sudo iptables -A INPUT -i lo -j ACCEPT

# Simple version of SSH incoming OK, stateless
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# SSH incoming OK, stateful
sudo iptables -A INPUT -i eth0 -p tcp --dport 22 -m conntrack --ctstate NEW, ESTABLISHED -j ACCEPT

# Accept packets from trusted IP addresses
sudo iptables -A INPUT -s 192.168.0.4 -j ACCEPT # change the IP address as appropriate
sudo iptables -A INPUT -s 192.168.0.0/24 -j ACCEPT  # using standard slash notation
sudo iptables -A INPUT -s 192.168.0.0/255.255.255.0 -j ACCEPT # using a subnet mask

# To block network connections that originate from a specific IP address, 15.15.15.51 for example, run this command:
sudo iptables -A INPUT -s 15.15.15.51 -j DROP

# Accept tcp packets on destination port 6881 (bittorrent)
sudo iptables -A INPUT -p tcp --dport 6881 -j ACCEPT

# Some network traffic packets get marked as invalid. Sometimes it can be useful to log this type of packet but often it is fine to drop them. Do so with this command:
sudo iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# To allow all incoming HTTPS (port 443) connections run these commands:
sudo iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -p tcp --sport 443 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Default catch-all in case you did not have a secure default policy
sudo iptables -A INPUT -j REJECT


##########FORWARD CHAIN

# Assuming eth0 is your external network, and eth1 is your internal network, this will allow your internal to access the external:
sudo iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT

sudo iptables -A FORWARD -j REJECT


##########OUTPUT CHAIN
sudo iptables -A OUTPUT -o lo -j ACCEPT

# HTTPS port allowed out, but not HTTP port
sudo iptables -A OUTPUT -p tcp --dport https -j ACCEPT
# sudo iptables -A OUTPUT -p tcp --dport http -j ACCEPT

# DNS allowed out on 53
sudo iptables -A OUTPUT -p udp --dport domain -j ACCEPT

# Output SSH allowed. You may want to allow outgoing traffic of all established connections, which are typically the response to legitimate incoming connections. This command will allow that:
sudo iptables -A OUTPUT -o eth0 -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Block a particular website (e.g., facebook):
# host -t a www.facebook.com says ip is:
sudo iptables -A OUTPUT -d 157.240.2.35 -j DROP

# Final catch-all in case you did not have a secure default policy
sudo iptables -A OUTPUT -j REJECT


sudo service iptables save


