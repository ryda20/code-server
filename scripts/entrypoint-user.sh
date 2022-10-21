#!/bin/bash
source /scripts/base.sh
# code below running as ${USER_NAME} - stduser


# check and enable AUTH if have PASSWORD env
# -n : noneempty string
# https://acloudguru.com/blog/engineering/conditions-in-bash-scripting-if-statements
log_title "setting password for code server"
if [ -n "${PASSWORD}" ] ; then
	AUTH="password"
	log "starting with password: \$PASSWORD"
else
	AUTH="none"
	log "starting with no password"
fi
log_end

# check and apply domain
log_title "setting domain for code server"
if [ -z ${PROXY_DOMAIN+x} ]; then
	PROXY_DOMAIN_ARG=""
else
	PROXY_DOMAIN_ARG="--proxy-domain=${PROXY_DOMAIN}"
fi
log_end

log_title "starting code server"
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
