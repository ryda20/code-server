#!/bin/bash

# code below running as ${USER_NAME} - stduser
basename=$(basename ${0})
dirname=$(dirname ${0})

log() {
	echo -e "[${basename}] $@"
}
log_title () {
	echo ""
	echo "=============================================="
	log "$@"
	echo "=============================================="
	echo ""
}

# check folder /autorunscripts to run specical file name 'run_me.sh'
log_title "scan and run custom init script from user"
source /scripts/autorunscripts.sh
auto_run_scripts "/autorunscripts"

log_title "auto link dotfiles to user home directory"
source /scripts/dotfiles.sh
auto_link_dotfiles "/dotfiles"
echo "=============================================="


# check and enable AUTH if have PASSWORD env
# -n : noneempty string
# https://acloudguru.com/blog/engineering/conditions-in-bash-scripting-if-statements
if [ -n "${PASSWORD}" ] ; then
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

mkdir -p ${MY_CONF}/extensions
mkdir -p ${MY_CONF}/data

exec ${MY_APPS}/code-server/bin/code-server \
			--bind-addr 0.0.0.0:8080 \
			--user-data-dir ${MY_CONF}/data \
			--extensions-dir ${MY_CONF}/extensions \
			--disable-telemetry \
			--auth "${AUTH}" \
			"${PROXY_DOMAIN_ARG}" \
			"${DEFAULTMY_WORKSPACE:-${MY_WORKS}}"
