#!/bin/bash

auto_link_dotfiles() {
	dir=${1:-/dotfiles}
	home=${2:-~}
	if [ -d ${dir} ] ; then
		# loop for hidden file .xxxx, not ..xxxx, * does not match with dot (.)
		for f in ${dir}/.[^.]* ; do
			fileName=$(basename ${f})
			linkedName=${home}/${fileName}  # file in home directory of current user
			#
			echo -e "-> linking ${f} -> ${linkedName}"
			# f: remove symbolic if it exist and a file
			# n: remove symbolic if it exist and a directory 
			ln -sfn ${f} ${linkedName}
		done
	fi
}

auto_link_dotfiles2() {
	dir=${1:-/dotfiles}
	home=${2:-~}
	if [ -d ${dir} ] ; then
		# loop for hidden file .xxxx, not ..xxxx, * does not match with dot (.)
		for f in ${dir}/.[^.]* ; do
			fileName=$(basename ${f})
			linkedName=${home}/${fileName}  # file in home directory of current user
			log "working on ${f} -> ${linkedName}"
			# check if file exist in $HOME directory (~)
			if [ -f "${linkedName}" ]; then
				echo -e "\t-> file already existed!"
				if [ ${f} -ef ${linkedName}  ]; then
					echo -e "\t\t-> same, no link again: ${f}"
				else
					rm ${linkedName}
					ln -s ${f} ${linkedName}
					echo -e "\t\t-> difference, removed, relinked ${linkedName} -> ${f}"
				fi
			elif [ -d "${linkedName}" ]; then
				echo -e "\t-> directory already existed!"
				# DIFF=$(diff a b) 
				# if [ "${DIFF}" != "" ]; then
				# 	rm -r ${linkedName}
				# 	ln -s ${f} ${linkedName}
				# 	echo "\t\t-> difference, removed, relinked ${linkedName} -> ${f}"
				# else
				# 	echo "\t\t-> same, no link again: ${f}"
				# fi
			else
				ln -sf ${f} ${linkedName}
				echo -e "\t-> linked ${f} -> ${linkedName}"
			fi
		done
	fi
}
