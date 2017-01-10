#!/bin/sh
# Functions for installation script.

# Format for printf output
outformat=" %s\t%s %s\n"

# Function: create default directory structure.
# Arguments: List of directories to be created.
createDirectoryStructure () {

	printf "$outformat" "${FUNCNAME}:" "I:" "Starting."

	if [ -z "$1" ]; then				# Verify at least one argument is passed.
		printf "$outformat" "${FUNCNAME}:" "ERROR:" "No arguments passed to function."
		exit 1
	fi

	for i in "$@"; do					# For each directory passed, create directory.
		if [ ! -d ${i} ]; then			# Verify directory does not already exist.
			printf "$outformat" "${FUNCNAME}:" "W:" "${i} Missing... Creating directory"
			mkdir -p ${i}; rc=$?		# Create directory and capture return code.
			if [ ${rc} = 0 ]; then
				printf "$outformat" "${FUNCNAME}:" "I:" "Created ${i} Successfully..."
			fi
		else
			printf "$outformat" "${FUNCNAME}:" "I:" "${i} already exists. Skipping."
		fi
	done

	printf "$outformat" "${FUNCNAME}:" "I:" "Completed."

}


# Function: Verify Java Installation
# Arguments: JAVA_HOME (ex. /usr/bin/java)
verifyJava () {

	printf "$outformat" "${FUNCNAME}:" "I:" "Starting."

	if [ -z "$1" ]; then				# Verify argument (JAVA_HOME) is passed.
		printf "$outformat" "${FUNCNAME}:" "E:" "JAVA_HOME variable is undefined."
		exit 1
	fi

	printf "$outformat" "${FUNCNAME}:" "I:" "Verification output:"
	${1} -version ; rc=$?				# Verify Java returns
	
	if [ ${rc} = 0 ]; then
		printf "$outformat" "${FUNCNAME}:" "I:" "Java install verified."
	else
		printf "$outformat" "${FUNCNAME}:" "ERROR:" "Unable to verify Java installation."
		exit 1
	fi

	printf "$outformat" "${FUNCNAME}:" "I:" "Completed."

}


# Function: Install Wildfly
# Arguments: Full file path to installatio media (ex. /opt/media/wildfly-8.2.0.Final.zip)
installWildfly () {


}
