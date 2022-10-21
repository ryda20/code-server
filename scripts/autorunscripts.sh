#!/bin/bash

# loop & print a folder recusively,
print_folder_recurse() {
	basename_old=${basename}
	dirname_old=${dirname}

    for f in "$1"/*;do
        if [ -d "${f}" ];then
            # recurse for directory
            print_folder_recurse "${f}"
        elif [ -f "${f}" ] ; then
			# basename=$(basename -- "${f}")
			# extension="${basename##*.}"
			# filename="${basename%.*}"
			# log "file: ${f}, basename: ${basename}, filename: ${filename}, extension: ${extension}"
			#
			# because we run run_me.sh script in autorunscripts by calling source command
			# show, the dirname (working dir) will be dirname of entrypoint.sh
			# but, in run_me.sh scripts (in autorunscripts) will use it own dirname,
			# so, we need to change dirname for them work correctly
			if [[ "$(basename -- ${f})" == "run_me.sh" ]] ; then
				# basename=$(basename ${0})
				# dirname=$(dirname ${0})
				# https://stackoverflow.com/questions/35006457/choosing-between-0-and-bash-source
				# or using ${BASH_SOURCE[0]} inside script file to find out basename and dirname
				# BASH_SOURCE is a full path to script file
				basename=$(basename "${f}") dirname=$(dirname "${f}") source "${f}"
			fi
        fi
    done
	basename=${basename_old}
	dirname=${dirname_old}
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
