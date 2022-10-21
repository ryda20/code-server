#!/bin/bash

NC='\033[0m' # No Color
Black='\033[0;30m'
DarkGray='\033[1;30m'
Red='\033[0;31m'
LightRed='\033[1;31m'
Green='\033[0;32m'
LightGreen='\033[1;32m'
BrownOrange='\033[0;33m'
Yellow='\033[1;33m'
Blue='\033[0;34m'
LightBlue='\033[1;34m'
Purple='\033[0;35m'
LightPurple='\033[1;35m'
Cyan='\033[0;36m'
LightCyan='\033[1;36m'
LightGray='\033[0;37m'
White='\033[1;37m'

colors[0]=${Black}
colors[1]=${DarkGray}
colors[2]=${LightGray}
colors[3]=${LightCyan}
colors[4]=${Green}
colors[5]=${LightGreen}
colors[6]=${BrownOrange}
colors[7]=${Yellow}
colors[8]=${Blue}
colors[9]=${LightBlue}
colors[10]=${Purple}
colors[11]=${LightPurple}
colors[12]=${Cyan}
# colors[13]=${LightRed}
# colors[14]=${Red}
# colors[15]=${White}

colors_size=${#colors[@]}
colors_index=0
colors_index_pre=0
random_color=${colors[$colors_index]}  # default color is black

equal_line="==============================================================================="

random_color_gen() {
	# generate random color
	colors_index=$(($RANDOM % $colors_size))
	if [[ ${colors_index} -eq ${colors_index_pre} ]]; then
		colors_index=$(($RANDOM % $colors_size))
	fi
	colors_index_pre=${colors_index}
	random_color=${colors[$colors_index]}
}


# works follow:
# log_title
# log
# ....
# log_end

log() {
	# echo -e "# $@"
	# some system dont show correctly color, so, i force to use
	echo -e "${random_color}# $@ ${NC}"
}

log_title() {
	random_color_gen

	# echo -e "${random_color}#${equal_line}"
	# # force Red color for script
	# echo -e "${Red}# script: ${0}"
	# # set back to random color
	# echo -e "${Red}# $@ ${random_color}"

	# force to use color for sure it display correctly because above code seems not working for all system
	echo -e "${random_color}#${equal_line}${NC}"
	echo -e "${random_color}#${Red} script: ${dirname}/${basename}${NC}"
	echo -e "${random_color}#${Red} $@ ${NC}"
}

log_end() {
	# clear color at the end
	echo -e "${random_color}#${equal_line}${NC}"
	# add more empty line
	echo ""
}
