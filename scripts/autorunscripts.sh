#!/bin/bash

# loop & print a folder recusively,
print_folder_recurse() {
    for f in "$1"/*;do
        if [ -d "${f}" ];then
            # recurse for directory
            print_folder_recurse "${f}"
        elif [ -f "${f}" ] ; then
			basename=$(basename -- "${f}")
			# extension="${basename##*.}"
			# filename="${basename%.*}"
			# log "file: ${f}, basename: ${basename}, filename: ${filename}, extension: ${extension}"
			if [[ "${basename}" == "run_me.sh" ]] ; then
				# log "working on ${f}"
				source "${f}"
			fi
        fi
    done
}

auto_run_scripts() {
	dir=${1:-/autorunscripts}
	if [ -d ${dir} ]; then
		# -exec bash will run script in new bash, so, not include all source of this current script like log, log_title,...
		# find ${dir} -type f -executable -name "run_me.sh" -exec bash {} \; -exec echo -e "Executed: {} \n" \;
		# but i want to use these functions in scripts inside autorunscripts directory,
		# so, using for and source command instead of find command 
		print_folder_recurse ${dir}	
	else
		log "autorunscripts not found!"
	fi
}

# allow to call functiion directly like:
# bash autorunscripts.sh auto_run_scripts para1
# "$@"
