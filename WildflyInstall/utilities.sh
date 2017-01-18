#!/bin/sh
# Functions for installation script.

# Format for printf output
outformat=" %s\t%s %s\n"

# Function:		Escapes special characters in a variable.
# Arguments:	Variable to escape
escapevar() {

	variable=$1
	escvariable=$(echo "${variable}" | sed 's/\\/\\&/g;s/\//\\&/g;s/\./\\&/g;s/\$/\\&/g;s/\*/\\&/g;s/\[/\\&/g;s/\]/\\&/g;s/\^/\\&/g')

	echo $escvariable

	return 0

}


# Function: 	Create default directory structure.
# Arguments: 	List of directories to be created.
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


# Function: 	Verify Java Installation
# Arguments: 	JAVA_HOME (ex. /usr/bin/java)
verifyJava () {

	printf "$outformat" "${FUNCNAME}:" "I:" "Starting."

	if [ -z "$1" ]; then				# Verify argument (JAVA_HOME) is passed.
		printf "$outformat" "${FUNCNAME}:" "ERROR:" "JAVA_HOME variable is undefined."
		exit 1
	fi

	printf "$outformat" "${FUNCNAME}:" "I:" "Verification output:"
	${1}/bin/java -version ; rc=$?				# Verify Java returns
	
	if [ ${rc} = 0 ]; then
		printf "$outformat" "${FUNCNAME}:" "I:" "Java install verified."
	else
		printf "$outformat" "${FUNCNAME}:" "ERROR:" "Unable to verify Java installation."
		exit 1
	fi

	printf "$outformat" "${FUNCNAME}:" "I:" "Completed."

}


# Function: 	Install Wildfly
# Arguments: 	MAIN_MEDIA (ex. /opt/media/wildfly-8.2.0.Final.zip)i, SOFTWARE_HOME 
# 				(ex. $HOME_DIR/software)
installWildfly () {

	printf "$outformat" "${FUNCNAME}:" "I:" "Starting."

	if [ -z "$1" ] || [ ! -f "$1" ]; then	# Verify argument (MEDIA_HOME) passed.
		printf "$outformat" "${FUNCNAME}:" "ERROR:" "Unable to locate ${1}."
		exit 1
	fi

	# Grab input variables
	media=${1}
	unpack_loc=${2}

	printf "$outformat" "${FUNCNAME}:" "I:" "Unpacking media to ${2}..."

	unzip -q $media -d $unpack_loc ; rc=$?

	if [ ${rc} = 0 ]; then
		printf "$outformat" "${FUNCNAME}:" "I:" "Media unpacked successfully."
	else
		printf "$outformat" "${FUNCNAME}:" "ERROR:" "Problem unpacking media."
		exit 1
	fi

	# Get location where media was extracted.
	unpacked_media_dir=$(ls ${unpack_loc} | grep -o "wildfly-[0-9]\.[0-9]\..*")

	# Remove end chars "-Final" to create new location.
	media_home_dir=$(sed -e 's/\.Final$//' <<< ${unpacked_media_dir})

	mv ${unpack_loc}/${unpacked_media_dir} ${unpack_loc}/${media_home_dir}  ; rc=$?		# Move extracted directory to new location

	if [ ${rc} = 0 ]; then
		printf "$outformat" "${FUNCNAME}:" "I:" "Unpacked media moved to ${unpack_loc}/${media_home_dir}."
	else
		printf "$outformat" "${FUNCNAME}:" "ERROR:" "Could not move unpacked media to ${unpack_loc}/${media_home_dir}."
		exit 1
	fi

	printf "$outformat" "${FUNCNAME}:" "I:" "Completed."

}


# Function:		Escape and replace custom variables
# Arguments:	Variable to be replaced, New string, file to udpate
replaceVar() {

	# set variables
	tarvar=$1
	newstring=$2
	file=$3

	sed -i "s/${tarvar}/$(escapevar ${newstring})/g" $file

}


# Function:		Generates a keystore w/ self-signed certificate, if keystore exists, skips creating
# 				new keystore.
# Arguments:	keystore name, cert alias (ex. hostname), output directory (ex. /opt/wildfly/ssl)
genKeystore () {

	jksname=$1
	certalias=$2
	outputdir=$3

	# Verify output directory and create if necessary
	if [ ! -d ${outputdir} ]; then
		printf "$outformat" "${FUNCNAME}:" "W:" "${outputdir} Missing... Creating directory."
		mkdir -p ${outputdir}; rc=$?        # Create directory and capture return code.
		if [ ${rc} = 0 ]; then
			printf "$outformat" "${FUNCNAME}:" "I:" "Created ${outputdir} Successfully..."
		fi
	else
		printf "$outformat" "${FUNCNAME}:" "I:" "${outputdir} already exists. Skipping."
	fi

	# Check for existence of keystore in default location (./ssl), if it exists, move to output dir,
	# 	if not, create new keystore 
	if [ ! -f ./ssl/${jksname} ]; then
	
		printf "$outformat" "${FUNCNAME}:" "I:" "$jksname not found in default ./ssl location, creating new keystore with '${certalias}' alias."
	
		# Create new keystore.
		keytool -genkey -keyalg RSA -alias ${certalias} -keysize 2048 -keystore ${outputdir}/${jksname}
		rc=$?

		if [ ${rc} = 0 ]; then
			printf "$outformat" "${FUNCNAME}:" "I:" "${jksname} created successfully in ${outputdir}."
		else
			printf "$outformat" "${FUNCNAME}:" "ERROR:" "Unable to create ${jksname} at ${outputdir}."
			exit 1
		fi

	else
		# If keystore file exists in default location, move to output directory.
		printf "$outformat" "${FUNCNAME}:" "W:" "$jksname found in default ./ssl location. Using that keystore."
		cp ./ssl/${jksname} ${outputdir} ; rc=$?	# Copy file.
		if [ ${rc} = 0 ]; then
			printf "$outformat" "${FUNCNAME}:" "I:" "Successfully copied $jksname to ${outputdir}."
		else
			printf "$outformat" "${FUNCNAME}:" "ERROR:" "Unable to copy $jksname to ${outputdir}."
		fi
	fi

}


# Function:		Add value to vault.
# Arguments:	WILDFLY HOME, Encrypted file directory, keystore url, keystore password, salt, keystore alias,
#				iteration count, attribute name, vault block, secured value (password), 'add' or 'check'
vaultAddItem () {

	# Map variables
	wildfly_home=$1
	enc_file_dir=$2
	url=$3
	pass=$4
	salt=$5
	key_alias=$6
	iteration=$7
	attribute=$8
	block=$9
	sec_value=${10}
	add_or_check=${11}

	# Verify vault.sh script
	if [ ! -f $wildfly_home/bin/vault.sh ]; then
		printf "$outformat" "${FUNCNAME}:" "ERROR:" "Unable to locate ${wildfly_home}/bin/vault.sh."
		exit 1
	fi

	if [ "$add_or_check" == "add" ]; then

		printf "$outformat" "${FUNCNAME}:" "I:" "Adding value to vault."

		# Add attribute
		$wildfly_home/bin/vault.sh -e $enc_file_dir -k $url -p "${pass}" -s $salt -v $key_alias -i $iteration -a $attribute -b $block -x "$sec_value" ; rc=$?
	
	elif [ "$add_or_check" == "check" ]; then

		printf "$outformat" "${FUNCNAME}:" "I:" "Checking for $attribute in $block block."
		# Check for attribute
		$wildfly_home/bin/vault.sh -e $enc_file_dir -k $url -p "${pass}" -s $salt -v $key_alias -i $iteration -a $attribute -b $block -c ; rc=$?

	fi

	if [ ${rc} == 0 ]; then
		printf "$outformat" "${FUNCNAME}:" "I:" "Vault process completed successfully."
	else
		printf "$outformat" "${FUNCNAME}:" "ERROR:" "Vault process did not complete successfully."
		exit 1
	fi

}


