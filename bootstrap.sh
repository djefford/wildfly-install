#!/bin/bash
# Script that can be used to prep Centos7 environment for wildfly installation.

# Install dependencies
yum update -y
yum install -y java-1.8.0-openjdk unzip net-tools vim

# Create wildfly user
useradd -s /bin/bash -d /home/wildfly wildfly
