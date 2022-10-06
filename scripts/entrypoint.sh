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
log_title "changing UID/GID... to ${PUID}:${PGID}"
log "user must send correct uid/gid (by PUID/PGID) for the mount workspace,\n because we dont change it permission"
if [ -n ${PUID} ] || [ -n ${PGID} ]; then
	log "changing uid/gid for user: ${USER_NAME}, group: ${GROUP_NAME}"
	groupmod -og ${PGID} ${GROUP_NAME}
	usermod -ou ${PUID} -g ${PGID} ${USER_NAME}
	#
	log "update [recursive] permission on ${USER_HOME_DIR}"
	chown -R ${USER_NAME}:${GROUP_NAME} ${USER_HOME_DIR}
	#
	log "update [recursive] permission on ${USER_APP_DIR}"
	chown -R ${USER_NAME}:${GROUP_NAME} ${USER_APP_DIR}
	#
	log "update permission on ${USER_WORKSPACE_DIR} only"
	chown ${USER_NAME}:${GROUP_NAME} ${USER_WORKSPACE_DIR}
fi

# # log_title "setup for auto change to ${USER_NAME} when start bash shell"
# # change user on every run bash
# # to prevent run in root user, apply for rootless mode (don't use USER directive in dockerfile)
# # put this file to /etc/profile.d/any_name.sh, remember chown to root and chmod to 400 or 600
# # echo "exec su ${USER_NAME}" >> /etc/profile.d/start.sh
# # OR
# echo "exec su ${USER_NAME}" >>/root/.bashrc #ENDRUN

log_title "changing 'root' user to '${USER_NAME}'..."
chmod 4755 $(which su)
exec su ${USER_NAME} -c '
log () {
	echo -e "[entrypoint.sh] $@"
}
log_title () {
	echo ""
	echo "=============================================="
	log "$@"
	echo "=============================================="
	echo ""
}

# check and enable AUTH if have PASSWORD env
# -n : noneempty string
# https://acloudguru.com/blog/engineering/conditions-in-bash-scripting-if-statements
if [ -n "${PASSWORD}" ] || [ -n "${HASHED_PASSWORD}" ]; then
	AUTH="password"
	log "starting with password: \$PASSWORD"
else
	AUTH="none"
	log "starting with no password"
fi

# check and apply domain
if [ -z ${PROXY_DOMAIN+x} ]; then
	PROXY_DOMAIN_ARG=""
else
	PROXY_DOMAIN_ARG="--proxy-domain=${PROXY_DOMAIN}"
fi

mkdir -p ${USER_HOME_DIR}/extensions
mkdir -p ${USER_HOME_DIR}/data
mkdir -p ${USER_HOME_DIR}/workspace
mkdir -p ${USER_HOME_DIR}/.ssh


exec /app/code-server/bin/code-server \
			--bind-addr 0.0.0.0:8080 \
			--user-data-dir ${USER_HOME_DIR}/data \
			--extensions-dir ${USER_HOME_DIR}/extensions \
			--disable-telemetry \
			--auth "${AUTH}" \
			"${PROXY_DOMAIN_ARG}" \
			"${DEFAULT_WORKSPACE:-${USER_WORKSPACE_DIR}}"
'

# bash startup file /etc/profile and load all file with .sh in /etc/profile.d/
# zsh -> ~/.zshrc
# https://blog.opstree.com/2020/02/11/shell-initialization-files/
# 1. Non-interactive mode:
# source file in $BASH_ENV
# 2. Interactive login mode:
# /etc/profile
# 3. Interactive non-login mode:
# /etc/bash.bashrc
