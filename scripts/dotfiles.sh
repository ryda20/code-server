#!/bin/bash

auto_link_dotfiles() {
	dir=${1:-/dotfiles}
	home=${2:-~}
	if [ -d ${dir} ] ; then
		# loop for hidden file .xxxx, not ..xxxx, * does not match with dot (.)
		for f in ${dir}/.[^.]* ; do
			fileName=$(basename ${f})
			linkedFile=${home}/${fileName}  # file in home directory of current user
			# check if file exist in $HOME directory (~)
			if [ -f  linkedFile ] ; then
				# check if same with my file
				if [ ${f} -ef ${linkedFile}  ]; then
					echo "same, no link again: ${f}"
				else
					rm ${linkedFile}
					ln -s ${f} $linkedFile
					echo "difference, removed, relinked ${linkedFile} -> ${f}"
				fi
			else
				ln -s ${f} ${linkedFile}
				echo "linked ${f} -> ${linkedFile}"
			fi
		done
	fi
}
