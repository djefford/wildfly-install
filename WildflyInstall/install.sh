#!/bin/sh
############################################################
# Author: Dustin Jefford
# 
# Description: Installs Red Hat JBoss EAP 7.x
#
############################################################

# Source support files
source ./utilities.sh 
source ./parameters

# Verify JAVA_HOME
if [ -z $JAVA_HOME ]; then
	JAVA_HOME=/usr/bin/java
fi

# Formatting values
length=50



#createDirectoryStructure $WHO_HOME $WHO_LOGS $DEV_HOME

#verifyJava $JAVA_HOME



verifyJava
