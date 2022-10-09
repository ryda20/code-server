#!/bin/bash

auto_run_scripts() {
	dir=${1:-/autorunscripts}
	if [ -d ${dir} ]; then
		find ${dir} -type f -executable -name "run_me.sh" -exec bash {} \; -exec echo "Executed: {}" \;
	else
		log "autorunscripts not found!"
	fi
}
