#!/bin/sh
############################################################
# Author: Dustin Jefford
# 
# Description: Installs, patches, and configures Wildfly 8.x
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
divider=`printf '=%.s' {1..40} ; echo`	# Prints dividing line of "=" in logging output.


echo $divider
printf " %s\n" "Starting $title Script..."
echo $divider

# Create initial directory structure.
printf " %s\n" "Verifying and creating directory structure."
echo $divider ; sleep 2

createDirectoryStructure $HOME_DIR $LOGS_DIR $DEV_HOME

echo $divider

# Verify Java installation.
printf " %s\n" "Verifying Java installation at ${JAVA_HOME}"
echo $divider ; sleep 2

verifyJava $JAVA_HOME

echo $divider

# Deploy JBoss
printf " %s\n" "Deploying Wildfly from ${MAIN_MEDIA} to ${SOFTWARE_HOME}"
echo $divider ; sleep 2

# InstallWildfly takes 2 arguments "MAIN_MEDIA" and "SOFTWARE_HOME"
installWildfly $MAIN_MEDIA $SOFTWARE_HOME

echo $divider

wildfly_dir=$(ls ${SOFTWARE_HOME} | grep -o "wildfly-[0-9]\.[0-9]\..*")		# Wildfly directory
wildfly_home=${SOFTWARE_HOME}/${wildfly_dir}								# Wildfly Home, full path

# Apply optional patches
printf " %s\n" "Patching Wildfly."
echo $divider ; sleep 2

# Loop over patch list and install each patch.
if [ ${#PATCH_LIST[@]} -gt 0 ]; then
	for patch in $PATCH_LIST; do
		patchWildfly $wildfly_home $patch
	done
else
	printf " %s\n" "No patches found. Skipping." ; sleep 2
fi

echo $divider

# Create SSL vaults - keystore.jks, and vault.jks
printf " %s\n" "Creating SSL keystores (keystore.jks and vault.jks)."
echo $divider ; sleep 2

# Create java keystore for wildfly.
genKeystore keystore.jks ${HOSTNAME} ${wildfly_home}/ssl

echo $divider

# Create vault keystore for wildfly
genKeystore vault.jks vault ${wildfly_home}/ssl

echo $divider

# Configure Vault.
printf " %s\n" "Configuring vault."
echo $divider ; sleep 2

# Read in vault password.
read -s -p " Please provide vault keystore password: " vault_pass
printf "\n"
echo $divider
read -s -p " Please provide java keystore password: " keystore_pass

# Add default keystore information to vault.
vaultAddItem ${wildfly_home} ${wildfly_home}/${VAULT_ENC_FILE_DIR} ${wildfly_home}/ssl/vault.jks "${vault_pass}" "$VAULT_SALT" $VAULT_ALIAS $VAULT_ITERATION_COUNT javaKeystorePwd javaKeystore $keystore_pass add

# Read in ldap password.
echo $divider
read -s -p " Please provide ldap bind account password: " ldap_pass
printf "\n"

# Add LDAP Bind account password to the vault.
vaultAddItem ${wildfly_home} ${wildfly_home}/${VAULT_ENC_FILE_DIR} ${wildfly_home}/ssl/vault.jks "${vault_pass}" "$VAULT_SALT" $VAULT_ALIAS $VAULT_ITERATION_COUNT ldapAuthPwd ldapAuth $ldap_pass add


# Verify input and capture masked password.
printf " %s\n" "Verifying attribute exists in vault."
masked_pass=`vaultAddItem ${wildfly_home} ${wildfly_home}/${VAULT_ENC_FILE_DIR} ${wildfly_home}/ssl/vault.jks "${vault_pass}" "$VAULT_SALT" $VAULT_ALIAS $VAULT_ITERATION_COUNT javaKeystorePwd javaKeystore $keystore_pass check | grep -o "\"MASK-.*\""`

masked_pass=$(sed -e 's/^"//' -e 's/"$//' <<<"$masked_pass")

echo $divider

# Substitue variables and configure wildfly.
printf " %s\n" "Updating configuration files with custom variables."
echo $divider ; sleep 2

printf " %s\n" "Moving ${INSTALL_TYPE} files to working directory..."
echo $divider ; sleep 2

# Move configuration files and cli script to working directory
# This preserves the original files for future use or comparison.
cp -r ./${INSTALL_TYPE} ./working

# Replace variables in cli and conf templates
for file in `ls ./working`; do

	file_loc="./working/$file"

	printf " %s\n" "Updating ${file_loc}..."

	# General replacements
	replaceVar "{{JAVA_HOME}}" "$JAVA_HOME" "$file_loc"
	replaceVar "{{WILDFLY_HOME}}" "${wildfly_home}" "$file_loc"
	replaceVar "{{WILDFLY_USER}}" "$WILDFLY_USER" "$file_loc"
	replaceVar "{{LOGS_DIR}}" "$LOGS_DIR" "$file_loc"
	replaceVar "{{HOSTNAME}}" "$HOSTNAME" "$file_loc"
	replaceVar "{{SMTP_SERVER}}" "$SMTP_SERVER" "$file_loc"

	# Vault replacements
	replaceVar "{{ENC_FILE_DIR}}" "$VAULT_ENC_FILE_DIR" "$file_loc"
	replaceVar "{{MASKED_VAULT_PASSWORD}}" "${masked_pass}" "$file_loc"
	replaceVar "{{VAULT_ALIAS}}" "$VAULT_ALIAS" "$file_loc"
	replaceVar "{{VAULT_SALT}}" "$VAULT_SALT" "$file_loc"
	replaceVar "{{ITERATION_COUNT}}" "$VAULT_ITERATION_COUNT" "$file_loc"

	# LDAP replacements
	replaceVar "{{LDAP_URL}}" "$LDAP_URL" "$file_loc"
	replaceVar "{{LDAP_BIND_DN}}" "$LDAP_BIND_DN" "$file_loc"
	replaceVar "{{LDAP_BASE_DN}}" "$LDAP_BASE_DN" "$file_loc"
	replaceVar "{{LDAP_NAME_ATTRIBUTE}}" "$LDAP_NAME_ATTRIBUTE" "$file_loc"
	replaceVar "{{LDAP_ADMIN_GROUP_DN}}" "$LDAP_ADMIN_GROUP_DN" "$file_loc"
	replaceVar "{{LDAP_ADMIN_GROUP}}" "$LDAP_ADMIN_GROUP" "$file_loc"
done

printf " %s\n" "Setting up configuration file in ${wildfly_home}/bin/${INSTALL_TYPE}."
mkdir ${wildfly_home}/bin/${INSTALL_TYPE}
cp ./working/wildfly.conf ${wildfly_home}/bin/${INSTALL_TYPE}

printf " %s\n" "Completed setting up ${wildfly_home}/bin/${INSTALL_TYPE}."

echo $divider

# Update and move scripts.
printf " %s\n" "Updating script files."
echo $divider ; sleep 2

printf " %s\n" "Moving script files to working_scripts directory..."
echo $divider ; sleep 2

# Move scripts to working_scripts directory
cp -r ./scripts ./working_scripts

# Replace variables
for file in `ls ./working_scripts` ; do

	file_loc="./working_scripts/$file"

	printf " %s\n" "Updating ${file_loc}..."

	# General replacements
	replaceVar "{{WILDFLY_HOME}}" "${wildfly_home}" "$file_loc"
	replaceVar "{{LOGS_DIR}}" "$LOGS_DIR" "$file_loc"
	replaceVar "{{WILDFLY_USER}}" "$WILDFLY_USER" "$file_loc"
	replaceVar "{{ADMIN_GROUP}}" "$ADMIN_GROUP" "$file_loc"
	replaceVar "{{INSTANCE_TYPE}}" "$INSTANCE_TYPE" "$file_loc"
	replaceVar "{{ADMIN_HOME}}" "$ADMIN_HOME" "$file_loc"

done

printf " %s\n" "Setting up script files in ${ADMIN_HOME}/scripts."
placeScripts ./working_scripts ${ADMIN_HOME}/scripts

printf " %s\n" "Completed setting up script files in ${ADMIN_HOME}/scripts."

echo $divider

# Running permissions script
printf " %s\n" "Updating permissions..."
echo $divider ; sleep 2

${ADMIN_HOME}/scripts/wildflyPerms.sh

echo $divider

# Start Wildfly, in preparation to run the CLI scripts
printf " %s\n" "Starting Wildfly..."
echo $divider ; sleep 2

startWildfly ${wildfly_home} ${ADMIN_HOME}/scripts/wildfly-init.sh ${INSTALL_TYPE} ; rc=$?

if [ "$rc" != 0 ] ; then
	printf " %s\n" "Unable to start Wildfly."
fi

echo $divider

# Apply CLI scripts
printf " %s\n" "Applying CLI scripts."
echo $divider ; sleep 2

for file_loc in `ls ./working/*.cli`; do

	executeCLI $wildfly_home "batch" $file_loc

done

# Stop Wildfly and finish the script
printf " %s\n" "Stopping wildfly..."
echo $divider ; sleep 2

executeCLI $wildfly_home "command" "shutdown"

printf " %s\n" "Script completed successfully."
echo $divider



