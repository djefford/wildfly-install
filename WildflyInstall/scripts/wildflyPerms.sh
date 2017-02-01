#!/bin/sh

############################################################
#
# Wildfly 8.X Root Permissions Script
#
# Description:	This script maintains the permissions of the Wildfly root
#			Each update or change gets a separate line to ease maintenance
#			and readability of the script.
#
############################################################

WILDFLY_HOME={{WILDFLY_HOME}}
LOG_ROOT={{LOGS_DIR}}
WILDFLY_USER={{WILDFLY_USER}}
ADMIN_GROUP={{ADMIN_GROUP}}

# Verify paths exist so we don't accidentally chagne permissions everywhere.
if [ -d "$WILDFLY_HOME" ] && [ -d "$LOG_ROOT" ] ; then
	# Set top level permissions
	chown -R $WILDFLY_USER:$ADMIN_GROUP $WILDFLY_HOME
	chown -R $WILDFLY_USER:$ADMIN_GROUP $LOG_ROOT
	
	chmod 755 $WILDFLY_HOME
	chmod 755 $LOG_ROOT
	
	# Remove other access
	chmod -R o-rwx $WILDFLY_HOME
	chmod -R o-rwx $LOG_ROOT
	
	# Set script permissions
	chmod -R ugo-w $WILDFLY_HOME/bin
	find $WILDFLY_HOME/bin -name "*.sh" | xargs chmod ug+x

	# Add additional lines below if more standalone instances are configured
	find $WILDFLY_HOME/bin -type d -name "{{INSTANCE_TYPE}}" | xargs chmod -R ug+w
	
	# Set vault permissions to allow admin group to write
	if [ "$(ls -A $WILDFLY_HOME)" ] ; then
		find $WILDFLY_HOME/vault -name "*.dat" | xargs chmod g+w
	fi
	
	# Set logs permissions
	chmod 755 $LOG_ROOT
	chown -R $WILDFLY_USER:$ADMIN_GROUP $LOG_ROOT
	chmod -R 750 $LOG_ROOT

else
	printf " %s\t%s" "WILDFLY CRONTAB:" "ERROR: Variable paths not set appropriately. Script did not execute."
fi
