#!/bin/sh

# this is for rootless, starting with normal user
# so, can change UID/GID
#

prefix="[entrypoint.sh] "
log () {
	echo -e "${prefix}$@"
}
log_title () {
	echo ""
	echo "=============================================="
	log "$@"
	echo "=============================================="
	echo ""
}

# log_title "whoami: $(whoami), $(id)"
# echo "$(which cat)"
# echo "$(which groupmod)"
# echo "$(which usermod)"
# sudo cat /etc/sudoers
# sudo cat /etc/passwd
# log ""
# sudo /usr/sbin/groupmod -og 100 stdUser
# sudo /usr/sbin/usermod -ou 99 -g 100 stdUser
# log "running ok -> $(id)"
# sudo cat /etc/passwd
# ## check and change EUID EGID if specify
# log_title "changing UID/GID..."
# if [ -n ${EUID} ] || [ -n ${EGID } ] ; then
# 	# change gid of group stdUser
# 	sudo groupmod -g ${EGID} stdUser
# 	# change uid and user group to new group id
# 	sudo usermod -u ${EUID} -g ${EGID} stdUser
# 	# update permission for all directory and file
# 	# => no need now because does not have any file created in $HOME yet
# 	# find / -uid 800 -exec chown -v -h 900 '{}' \; && \
# 	# find / -gid 700 -exec chgrp -v 600 '{}' \;
# fi

# # check if use set sudo password
# if [ -n "${SUDO_PASSWORD}" ] || [ -n "${SUDO_PASSWORD_HASH}" ]; then
# 	echo "setting up sudo access"
# 	if ! grep -q 'stdUser' /etc/sudoers; then
# 		echo "adding stdUser to sudoers"
# 		echo "stdUser ALL=(ALL:ALL) ALL" >> /etc/sudoers
# 	fi
# 	if [ -n "${SUDO_PASSWORD_HASH}" ]; then
# 		echo "setting sudo password using sudo password hash"
# 		sed -i "s|^stdUser:\!:|stdUser:${SUDO_PASSWORD_HASH}:|" /etc/shadow
# 	else
# 		echo "setting sudo password using SUDO_PASSWORD env var"
# 		echo -e "${SUDO_PASSWORD}\n${SUDO_PASSWORD}" | passwd stdUser
# 	fi
# fi

log_title "whoami: $(whoami), $(id)\nEPUI:EPGID = ${EPUID}:${EPGID}"


# # note: below is working but when exec or attach from docker, user still as root
# # this mean, below only for this script session
#
# ### exec will replace running process (by root above) with the new one (by stdUser below)
# #
# echo ""
# echo "=============================================="
# echo "changing 'root' user to 'stdUser'..."
# echo "=============================================="
# # echo "$(which su) - $(ls -lash $(which su))"
# # chmod 4755 $(which su)
# # exec su "stdUser" "$0" -- "$@"
# # -p -m do not set new $HOME, $SHELL, $USER, $LOGNAME
# # exec su -p -m "stdUser" -c "/stdUser_startUp.sh"
# exec su "stdUser"

#
## we are under stdUser
#

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


mkdir -p ${USERMY_HOME_DIR}/extensions
mkdir -p ${USERMY_HOME_DIR}/data
mkdir -p ${USERMY_HOME_DIR}/workspace
mkdir -p ${USERMY_HOME_DIR}/.ssh


exec /app/code-server/bin/code-server \
			--bind-addr 0.0.0.0:8080 \
			--user-data-dir ${USERMY_HOME_DIR}/data \
			--extensions-dir ${USERMY_HOME_DIR}/extensions \
			--disable-telemetry \
			--auth "${AUTH}" \
			"${PROXY_DOMAIN_ARG}" \
			"${DEFAULTMY_WORKSPACE:-${USERMY_HOME_DIR}/workspace}"
