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
title="WildflyInstall" 					# String used in log messages related to full script.
length=40
divider="===================="


printf '=%.s' {1..40} ; echo
printf " %s\n" "Starting $title Script..."
printf '=%.s' {1..40} ; echo

createDirectoryStructure $HOME_DIR $LOGS_DIR $DEV_HOME

#VerifyJava $JAVA_HOME


