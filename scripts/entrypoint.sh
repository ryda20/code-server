#!/bin/sh
set -e
#
# this container will run root (default)
# this entrypoint is starting with root user
# after that, it swich to normal user
# so, we can do anything when in root user
# like: change UID,GID in case bind mount volume have owner id different from default user in container
#
log() {
	echo -e "[entrypoint.sh] $@"
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

### exec will replace running process (by root above) with the new one (by stdUser below)

## check and change PUID PGID if specify
_gid=$(id -g ${GROUP_NAME})
_uid=$(id -u ${USER_NAME})
log_title "Checking for UID/GID.
	User must send correct uid/gid (by PUID/PGID env) for the mount workspace,
	because we dont change it permission
"
if [ -n ${PGID} ] && [ ${_gid} -ne ${PGID} ]; then
	log "changing GID from ${_gid} to ${PGID}"
	groupmod -og ${PGID} ${GROUP_NAME}
fi

if [ -n ${PUID} ] && [ ${_uid} -ne ${PUID} ] ; then
	log "changing UID from ${_uid} to ${PUID}"
	usermod -ou ${PUID} ${USER_NAME}
fi

# do not need update chown USER:GROUP again because we already change USER:GROUP id
# under the hood, linux use uid and gid
# if [ -n ${PUID} ] || [ -n ${PGID} ] && [ $((id -u ${USER_NAME})) -ne ${PUID} ] && [ $((id -g ${GROUP_NAME})) -ne ${PGID} ]; then
# 	log "changing uid/gid for user: ${USER_NAME}, group: ${GROUP_NAME}"
# 	groupmod -og ${PGID} ${GROUP_NAME}
# 	usermod -ou ${PUID} -g ${PGID} ${USER_NAME}
# 	#
# 	log "update [recursive] permission on ${USER_HOME_DIR}"
# 	chown -R ${USER_NAME}:${GROUP_NAME} ${USER_HOME_DIR}
# 	#
# 	log "update [recursive] permission on ${USER_APP_DIR}"
# 	chown -R ${USER_NAME}:${GROUP_NAME} ${USER_APP_DIR}
# 	#
# 	log "update permission on ${WORKSPACE_DIR} only"
# 	chown ${USER_NAME}:${GROUP_NAME} ${WORKSPACE_DIR}
# fi

# # log_title "setup for auto change to ${USER_NAME} when start bash shell"
# # change user on every run bash
# # to prevent run in root user, apply for rootless mode (don't use USER directive in dockerfile)
# # put this file to /etc/profile.d/any_name.sh, remember chown to root and chmod to 400 or 600
# # echo "exec su ${USER_NAME}" >> /etc/profile.d/start.sh
# # OR
# echo "exec su ${USER_NAME}" >>/root/.bashrc #ENDRUN

log_title "changing 'root' user to '${USER_NAME}'..."
chmod 4755 $(which su)
exec su ${USER_NAME} -c /scripts/entrypoint-user.sh
