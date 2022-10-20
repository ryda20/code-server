#!/bin/sh
set -e
#
# this container will run root (default)
# this entrypoint is starting with root user
# after that, it swich to normal user
# so, we can do anything when in root user
# like: change UID,GID in case bind mount volume have owner id different from default user in container
#
basename=$(basename ${0})
dirname=$(dirname ${0})

log() {
	echo -e "[${basename}] $@"
}
log_title() {
	echo ""
	echo "=============================================="
	log "$@"
	echo "=============================================="
	echo ""
}

log_title "whoami: $(whoami), $(id)\nPUID:PGID = ${PUID}:${PGID}"

if [ -f "/sbin/openrc" ]; then
	log_title "starting openrc"
	/sbin/openrc
fi

if [ -f "/etc/init.d/sshd" ]; then
	log_title "starting sshd"
	/etc/init.d/sshd start
fi

#note: below is working but when exec or attach from docker, user still as root
# this mean, below only for this script session

log_title "auto link dotfiles to user home directory"
source /scripts/dotfiles.sh
# link for stduser
auto_link_dotfiles "/dotfiles" ${MY_HOME}
# link for root
auto_link_dotfiles "/dotfiles"
echo "=============================================="

# check folder /autorunscripts to run specical file name 'run_me.sh'
log_title "find and run scripts from autorunscripts"
source /scripts/autorunscripts.sh
auto_run_scripts "/autorunscripts"


### exec will replace running process (by root above) with the new one (by stdUser below)

## check and change PUID PGID if specify
_gid=$(id -g ${MY_GROUP})
_uid=$(id -u ${MY_USER})
log_title "Checking for UID/GID.
User must send correct uid/gid (by PUID/PGID env) for the mount ${MY_WORKS}, because we dont change it permission
"
if [ -n ${PGID} ] && [ ${_gid} != ${PGID} ]; then
	log "changing GID from ${_gid} to ${PGID}"
	groupmod -og ${PGID} ${MY_GROUP}
fi
#
if [ -n ${PUID} ] && [ ${_uid} != ${PUID} ] ; then
	log "changing UID from ${_uid} to ${PUID}"
	usermod -ou ${PUID} ${MY_USER}
fi
# we don't re-apply permission for HOME dir because usermod already do it for us
# comments out if APPS, WORKS, CONF inside HOME directory
# - h option will works on symbolic links instead of their referenced files
# if [ ${_gid} -ne ${PGID} ] ; then
# 	echo "re-apply gid permission for ${MY_APPS} and ${MY_CONF}"
# 	find ${MY_APPS} -group ${_gid} -exec chgrp -h ${MY_GROUP} {} \;
# 	find ${MY_CONF} -group ${_gid} -exec chgrp -h ${MY_GROUP} {} \;	
# fi
# i think change for user was enough to use
if [ ${_uid} != ${PUID} ] ; then
	echo "re-apply uid permission for ${MY_APPS} and ${MY_CONF}"
	find ${MY_APPS} -user ${_uid} -exec chown -h ${MY_USER} {} \;
	find ${MY_CONF} -user ${_uid} -exec chown -h ${MY_USER} {} \;
	# echo "re-apply uid:gid for ${MY_WORKS}"
	chown ${MY_USER}:${MY_GROUP} ${MY_APPS} ${MY_CONF} ${MY_WORKS}
fi


log_title "setup for auto change to ${MY_USER} when start bash shell"
# # change user on every run bash
# # to prevent run in root user, apply for rootless mode (don't use MY_USER directive in dockerfile)
# # put this file to /etc/profile.d/any_name.sh, remember chown to root and chmod to 400 or 600
# # echo "exec su ${MY_USER}" >> /etc/profile.d/start.sh
# # OR
# echo "exec su ${MY_USER}" >>/root/.bashrc



log_title "changing 'root' user to '${MY_USER}'..."
# chmod 4755 $(which su)
exec su ${MY_USER} -c /scripts/entrypoint-user.sh
