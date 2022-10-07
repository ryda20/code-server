#!/bin/bash

# code below running as ${USER_NAME} - stduser
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

mkdir -p ${CONFIG_DIR}/extensions
mkdir -p ${CONFIG_DIR}/data
mkdir -p ${USER_HOME_DIR}/.ssh


exec /app/code-server/bin/code-server \
			--bind-addr 0.0.0.0:8080 \
			--user-data-dir ${CONFIG_DIR}/data \
			--extensions-dir ${CONFIG_DIR}/extensions \
			--disable-telemetry \
			--auth "${AUTH}" \
			"${PROXY_DOMAIN_ARG}" \
			"${DEFAULT_WORKSPACE:-${WORKSPACE_DIR}}"
