#!/bin/bash
# Script that can be used to prep Centos7 environment for wildfly installation.

# Update /etc/hosts for accuracy
ip_addr=$(ip addr show enp0s8 | grep "inet " | cut -d ' ' -f 6 | awk -F"/" '{ print $1}')

echo "Updating the /etc/hosts file"
cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
${ip_addr}  $(hostname -f) $(hostname -s)
EOF

# Install dependencies
yum update -y
yum install -y java-1.8.0-openjdk zip unzip net-tools vim mailcap

# Create wildfly users and groups
useradd -s /bin/bash -d /home/wildfly wildfly

groupadd wfadmin

usermoad -a -G wfadmin vagrant
