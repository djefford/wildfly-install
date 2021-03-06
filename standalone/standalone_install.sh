#!/bin/bash
##################################################
# Description: Installs, patches, and configures Wildfly in standalone mode
#
# This script is designed to be called one directory higher than it is placed
#   in the repository.
# Author: Dustin Jefford
##################################################
set -u

source ./utilities
source ./parameters

VERSION="11"

print_divider
print_title "Starting Wildfly $VERSION Installation in standalone mode"
print_divider ; sleep 2

print_title "Gathering User Input" ; sleep 2

# Gather user input.
read -p "-- Customize keystore and admin user passwords? (y/n): " customize ; echo ""
if [[ "$customize" == "y" ]] ; then
  read -s -p "-- New password for java keystore: " java_jks_pass ; echo ""
  read -s -p "-- New password for vault keystore: " vault_jks_pass ; echo ""
else
  java_jks_pass="changeit"
  vault_jks_pass="changeit"
fi

# Verify Java is available
print_divider
print_title "Verifying Java Installation" ; sleep 2

# Try to locate java executable
if type -p java ; then
  print_line "Found 'java' executable in PATH"
  _java=java
elif [[ -n "${JAVA_HOME}" ]] && [[ -x "${JAVA_HOME}/bin/java" ]] ; then
  print_line "Found 'java' executable in JAVA_HOME"
else
  print_line "Unable to locate 'java' executable"
  exit 1
fi

# Verify and create software directories
print_divider
print_title "Creating Base Directories" ; sleep 2

create_dir "${WILDFLY_HOME}"
create_dir "${LOGS_DIR}"

# Extract Wildfly base media
print_divider
print_title "Extracting Wildfly Media" ; sleep 2

mkdir -p ./working/media

extract_zip_media $MAIN_MEDIA ./working/media

# Move unpacked directory to WILDFLY_HOME
mv ./working/media/wildfly-11.0.0.Final/* $WILDFLY_HOME ; rc=$?
rc_eval "${rc}" "Successfully moved media to ${WILDFLY_HOME}." \
  "ERROR: Failed to move media to ${WILDFLY_HOME}."

# Place keystore and vault jks files in appropriate location.
print_divider
print_title "Placing SSL keystore files" ; sleep 2

cp -r "./ssl" "${WILDFLY_HOME}/" ; rc=$?
rc_eval "${rc}" "Moved SSL keystores to ${WILDFLY_HOME}." \
  "ERROR: Failed to move SSL keystores to ${WILDFLY_HOME}."

# Rotate keystore passwords if custom option requested.
if [[ "${customize}" == "y" ]]; then
  print_divider
  print_title "Updating Keystore Passwords"

  change_keystore_pass "${WILDFLY_HOME}/ssl/keystore.jks" \
    "appserver" "changeit" "${java_jks_pass}"

fi

# Initialize Vault and store secrets
print_divider
print_title "Configuring Vault and Adding Secrets" ; sleep 2

vault_add_item $vault_jks_pass javaKeystorePwd javaKeystore $java_jks_pass

# Grab masked password for vault for later use
vault_mask_pass=`vault_add_item $vault_jks_pass vaultAuthPwd vaultAuth $vault_jks_pass \
  | grep -o "\"MASK-.*\""`

# Remove beginning and trailing "
vault_mask_pass=$(sed -e 's/^"//' -e 's/".*$//' <<<"$vault_mask_pass")

# Backup and Update template files
print_divider
print_title "Updating Templates" ; sleep 2

# Set-up dynamic variables
short_hostname=$(sed -e 's/\..*//' <<<"$HOSTNAME")

# Check for optional IP, if none, try to determine IP address
if [ -z "${OPT_IP}" ]; then
  ip_addr=$(sed -e 's/ $//' <<<"$(hostname -I)")
else
  ip_addr="${OPT_IP}"
fi

cp -r standalone/templates ./working

for file in `ls ./working/templates`; do
  file_loc="./working/templates/$file"

  replace_var "{{WILDFLY_HOME}}" "$WILDFLY_HOME" "$file_loc"
  replace_var "{{JAVA_HOME}}" "$JAVA_HOME" "$file_loc"
  replace_var "{{LOGS_DIR}}" "$LOGS_DIR" "$file_loc"
  replace_var "{{HOSTNAME}}" "$HOSTNAME" "$file_loc"
  replace_var "{{WILDFLY_USER}}" "$WILDFLY_USER" "$file_loc"
  replace_var "{{ADMIN_GROUP}}" "$ADMIN_GROUP" "$file_loc"

  replace_var "{{SHORT_HOSTNAME}}" "$short_hostname" "$file_loc"
  replace_var "{{IP_ADDR}}" "$ip_addr" "$file_loc"

  replace_var "{{VAULT_ENC_FILE_DIR}}" "$VAULT_ENC_FILE_DIR" "$file_loc"
  replace_var "{{VAULT_SALT}}" "$VAULT_SALT" "$file_loc"
  replace_var "{{VAULT_ITERATION_COUNT}}" "$VAULT_ITERATION_COUNT" "$file_loc"
  replace_var "{{VAULT_ALIAS}}" "$VAULT_ALIAS" "$file_loc"
  replace_var "{{VAULT_KEYSTORE}}" "$VAULT_KEYSTORE" "$file_loc"

  replace_var "{{VAULT_MASKED_PASSWORD}}" "$vault_mask_pass" "$file_loc"

  print_line "Updated ${file_loc}"

done

# Place scripts and configuration files
print_divider
print_title "Placing Scripts and Configuration Files" ; sleep 2

mkdir -p ${WILDFLY_HOME}/conf/standalone
mkdir -p ${WILDFLY_HOME}/conf/scripts
mkdir -p ${WILDFLY_HOME}/conf/crontabs

cp ./working/templates/wildfly.conf ${WILDFLY_HOME}/conf/standalone
cp ./working/templates/wildfly\@.service ${WILDFLY_HOME}/conf/scripts
cp ./working/templates/wildflyPerms.sh ${WILDFLY_HOME}/conf/crontabs/

# Update permissions in preparation for initial start-up
print_divider
print_line "Updating Permissions" ; sleep 2

${WILDFLY_HOME}/conf/crontabs/wildflyPerms.sh ; rc=$?

rc_eval "${rc}" "I: Successfully updated permissions." \
  "E: Permissions updates failed."

# Start Wildfly
print_divider
print_line "Starting Wildfly $VERSION" ; sleep 2

start_stop_standalone start

# print_divider
# print_line "Start: Standard configuartion of standalone instance"
#
# execute_cli_script ${ip_addr} ./working/templates/standalone-general.cli
#
# print_line "Finish: Standard configuration of standalone instance"
#
# if [ "$ldap_go" == "y" ]; then
#   print_line "Start: External LDAP configuration."
#   execute_cli_script ${ip_addr} ./working/templates/standalone-ldap.cli
#   print_line "Finish: External LDAP configuration."
# else
#   print_line "Start: Add local admin user."
#   add_local_user admin "$local_admin_pass"
#   print_line "Finish: Add local admin user."
# fi
#
# print_divider
#
# print_line "Start: Stopping wildfly." ; sleep 2
#
# start_stop_standalone stop
#
# print_line "Placing custom jboss-cli.xml script."
# cp ./working/templates/jboss-cli.xml ${WILDFLY_HOME}/bin/
#
# print_line "Finish: Stopping wildfly."
#
# print_divider
#
# print_line "Wildfly Installation completed in standalone mode."
#
# print_divider
# print_divider
