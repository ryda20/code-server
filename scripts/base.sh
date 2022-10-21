#!/bin/bash

basename=$(basename ${0})
dirname=$(dirname ${0})

equal_line="============================================================================================"
log() {
	echo -e "# $@"
}

log_title() {
	echo ""
	echo "#${equal_line}"
	log  "script: ${0}"
	log  "$@"
}

log_end() {
	echo "#${equal_line}"
}
