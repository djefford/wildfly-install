#!/bin/sh
# Functions for installation script.


# Function: create default directory structure.
# Arguments: List of directories to be created.
createDirectoryStructure () {

	printf "${FUNCNAME}: I: Starting.\n"

	if [ -z "$1" ]; then				# Verify at least one argument is passed.
		printf "${FUNCNAME}: ERROR: No arguments passed to function.\n"
		exit 1
	fi

	for i in "$@"; do					# For each directory passed, create directory.
		if [ ! -d ${i} ]; then			# Verify directory does not already exist.
			printf "${FUNCNAME}: W: ${i} Missing... Creating directory\n"
			mkdir -p ${i}; rc=$?		# Create directory and capture return code.
			if [ ${rc} = 0 ]; then
				printf "${FUNCNAME}: I: Created ${i} Successfully...\n"
			fi
		else
			printf "${FUNCNAME}: I: ${i} already exists. Skipping.\n"
		fi
	done

	printf "${FUNCNAME}: I: Completed.\n"

}


# Function: Verify Java Installation
# Arguments: JAVA_HOME (ex. /usr/bin/java)
verifyJava () {

	printf "${FUNCNAME}: I: Starting.\n"

	if [ -z "$1" ]; then				# Verify argument (JAVA_HOME) is passed.
		printf "${FUNCNAME}: E: JAVA_HOME variable is undefined.\n"
		exit 1
	fi

	${1} -version ; rc=$?				# Verify Java returns
	
	if [ ${rc} = 0 ]; then
		printf "${FUNCNAME}: I: Java install verified. Please record version number...\n"
		sleep 5
	else
		printf "${FUNCNAME}: ERROR: Unable to verify Java installation.\n"
		exit 1
	fi

	printf "${FUNCNAME}: I: Completed.\n"

} 
