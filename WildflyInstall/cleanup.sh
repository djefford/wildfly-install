#!/bin/sh

############################################################
#
# A cleanup script to remove directories and scripts from 
#	the installation of wildfly.
#
############################################################

source ./parameters

# check for and remove Wildfly Home
wildfly_home=$(ls ${SOFTWARE_HOME} | grep -o "wildfly-[0-9]\.[0-9]\..*")
wildfly_home=${SOFTWARE_HOME}/${wildfly_home}

if [ -d ${wildfly_home} ]; then
	printf " %s\n" "Removing ${wildfly_home}."
	rm -rf ${wildfly_home}
else
	printf " %s\n" "Unable to locate ${wildfly_home}."
fi

# Check for and remove logs directory
if [ -d ${LOGS_DIR} ]; then
	printf " %s\n" "Removing ${LOGS_DIR}."
	rm -rf ${LOGS_DIR}
else
	printf " %s\n" "Unable to locate ${LOGS_DIR}."
fi

# Check for and remove working directories
if [ -d ./working ]; then
	printf " %s\n" "Removing ./working."
	rm -rf ./working
else
	printf "%s\n" "Unable to locate ./working."
fi

if [ -d ./working_scripts ]; then
	printf " %s\n" "Removing ./working_scripts."
	rm -rf ./working_scripts
else
	printf " %s\n" "Unable to locate ./working_scripts."
fi


