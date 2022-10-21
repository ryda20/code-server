
FROM ryda20/alpine:3.16

ENV \
	# env for this dockerfile
	VERSION=4.7.1 \
	PORT=8080 \
	PROXY_DOMAIN="" \
	PASSWORD="${PASSWORD:-changeme}" \
	SUDO_PASSWORD="123"

# supply your pub key via `--build-arg ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"` when running `docker build`
# 
ARG \
	install_openrc="yes" \
	install_sshd="yes" \
	ssh_public_key=""

RUN \
	# check and change user/group id at the build time if the input uid/gid is difference with default value
	# for faster change in entrypoint (because it will skip the right permission on files)
	_gid=$(id -g ${MY_GROUP}) && \
	_uid=$(id -u ${MY_USER}) && \
	#
	if [ -n ${PGID} ] && [ ${_gid} != ${PGID} ]; then \
		log "changing GID from ${_gid} to ${PGID}"; \
		groupmod -og ${PGID} ${MY_GROUP}; \
	fi && \
	#
	if [ -n ${PUID} ] && [ ${_uid} != ${PUID} ] ; then \
		log "changing UID from ${_uid} to ${PUID}"; \
		usermod -ou ${PUID} ${MY_USER}; \
	fi #ENDRUN

RUN \
	if [ -n "${SUDO_PASSWORD}" ]; then \
		echo "set password for root user"; \
		echo -e "${SUDO_PASSWORD}\n${SUDO_PASSWORD}" | passwd root ; \
	fi #ENDRUN

# RUN \
# 	# check if use set sudo password
# 	if [ -n "${SUDO_PASSWORD}" ] || [ -n "${SUDO_PASSWORD_HASH}" ]; then \
# 	echo "setting up sudo access" ; \
# 	if ! grep -q '${MY_USER}' /etc/sudoers; then \
# 	echo "adding ${MY_USER} to sudoers" ; \
# 	echo "${MY_USER} ALL=(ALL:ALL) ALL" >> /etc/sudoers ; \
# 	fi && \
# 	if [ -n "${SUDO_PASSWORD_HASH}" ]; then \
# 	echo "setting sudo password using sudo password hash" ; \
# 	sed -i "s|^${MY_USER}:\!:|${MY_USER}:${SUDO_PASSWORD_HASH}:|" /etc/shadow ; \
# 	else \
# 	echo "setting sudo password using SUDO_PASSWORD env var" ; \
# 	echo -e "${SUDO_PASSWORD}\n${SUDO_PASSWORD}" | passwd ${MY_USER} ; \
# 	fi ; \
# 	else \
# 	echo "allow ${MY_USER} can change his UID/GID only" ; \
# 	# echo -e '${MY_USER} ALL = (root:root) NOPASSWD: \
# 	# /bin/cat,  \
# 	# /usr/sbin/groupmod -og $EGID ${MY_USER}, \
# 	# /usr/sbin/groupmod -g 0 ${MY_USER}, \
# 	# /usr/sbin/groupmod -og 0 ${MY_USER}, \
# 	# /usr/sbin/usermod -ou $EUID -g $EGID ${MY_USER}, \
# 	# /usr/sbin/usermod -u 0 -g 0 ${MY_USER}, \
# 	# /usr/sbin/usermod -ou 0 -g 0 ${MY_USER}' \
# 	# >> /etc/sudoers ; \
# 	# echo "${MY_USER} ALL = (root:root) NOPASSWD: /bin/sed -i /etc/passwd -r 's/1000:1000/$PUID:$PGID/g'" >> /etc/sudoers ; \
# 	# marlena ALL = NOPASSWD: /bin/systemctl restart nginx.service
# 	# /bin/cat
# 	# /usr/sbin/groupmod
# 	# /usr/sbin/usermod
# 	fi #ENDRUN


# RULE TO WRITE RUN COMMAND FOR AUTO GENERATE PRODUCT DOCKERFILE
# AFTER RUN, USING \ TO WRITE CODE IN NEW LINE
# AND THE LAST LINE OF CODE, COMMAND WITH '#ENDRUN'
# EXCEPT FOR THE LAST RUN, DONT WRITE #ENDRUN
RUN \
	if [[ "${install_openrc}" == "yes" ]] ; then \
		echo "*** Install OPENRC ***" ; \
		apk add --update --no-cache openrc ; \
		mkdir -p /run/openrc ; \
		# touch softlevel because system was initialized without openrc
		touch /run/openrc/softlevel ; \
	fi #ENDRUN

RUN \
	if [ "${install_sshd}" == "yes" ] ; then \
	echo "*** Install OpenSSH ***" ; \
	# openssh require openrc
	apk add --no-cache openssh ; \
	# mkdir -p /root/.ssh ; \
	# chmod 0700 /root/.ssh ; \
	ssh-keygen -A ; \
	echo -e "PasswordAuthentication no" >> /etc/ssh/sshd_config ; \
	rc-update add sshd default; \
	fi #ENDRUN

RUN \
	echo "*** Install dependencies ***" && \
	apk --no-cache --update add \
	zsh \
	curl \
	libc6-compat gcompat \
	# gnupg \
	nodejs \
	# openssh-client \
	# already add from base image
	# shadow \
	### fix ld-linux-x86-64.so.2 not found - comment out because already exist after install libc6-compat and gcompat
	#mkdir /lib64 && 
	#ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
	git #ENDRUN


RUN \	
	echo "*** Install code-server ${CODE_RELEASE} ***" && \
	if [ -z ${CODE_RELEASE+x} ]; then \
		CODE_RELEASE=$(curl -sX GET https://api.github.com/repos/coder/code-server/releases/latest | awk '/tag_name/{print $4;exit}' FS='[""]' | sed 's|^v||'); \
	fi && \
	# MY_USER_APP: defined in base image
	mkdir -p ${MY_APPS}/code-server && \
	curl -o /tmp/code-server.tar.gz -L "https://github.com/coder/code-server/releases/download/v${CODE_RELEASE}/code-server-${CODE_RELEASE}-linux-amd64.tar.gz" && \
	tar xf /tmp/code-server.tar.gz -C ${MY_APPS}/code-server --strip-components=1 && \
	#
	echo "remove original node execute file from code-server/lib folder" && \
	rm ${MY_APPS}/code-server/lib/node && \
	#
	### check and remove unuse shortcut
	# remove node shortcut
	# -h determine file is a symbolic link
	if [ -f "${MY_APPS}/code-server/node" ] && [ -h "${MY_APPS}/code-server/node" ] ; then \
	rm ${MY_APPS}/code-server/node ; \
	fi && \
	# remove code-server shortcut
	if [ -f "${MY_APPS}/code-server/code-server" ] && [ -h "${MY_APPS}/code-server/code-server" ] ; then \
	rm ${MY_APPS}/code-server/code-server ; \
	fi && \
	# replace exec path from node to code-server in new path
	sed -i 's+"$ROOT\/lib\/node"+node+g' ${MY_APPS}/code-server/bin/code-server && \
	#
	echo "*** fix fira code fonts for vscode server ***" && \
	#
	# grep: Search for PATTERN in FILEs (or stdin)
	# -r = recurse, -l = Show only names of files that match
	# xargs: Run PROG on every item given by stdin
	# for faster search, we can use find with limited on extensions of file then exec with grep
	#
	# find workbench.html and add link to Fira Code font from google.
	# as i know, needed to import url font to workbench.html in workbench_dir, but we search (find) for sure they change it 
	# to differenc location of later version
	# d="${MY_APPS}/code-server/lib/vscode/out/vs/workbench" && \
	d="${MY_APPS}/code-server" && \
	f="</head>" &&\
	r="<style>@import url('https://fonts.googleapis.com/css2?family=Fira+Code\&display=swap');</style></head>" && \
	find ${d} -name workbench.html -exec sed -i "s%${f}%${r}%g" {} \; && \
	# as i know for now, it is in code-server/lib/vscode/out/vs/server/node/server.main.js
	# maybe change in diffence version, so, for easy, we search it but in small place for faster
	f="style-src 'self' 'unsafe-inline'" && \
	r="style-src 'self' 'unsafe-inline' fonts.googleapis.com" && \
	f2="font-src 'self' blob:" && \
	r2="font-src 'self' blob: fonts.gstatic.com" && \
	# grep -rl "${f}" ${d} | xargs sed -i "s/${f}/${r}/g" && \
	# group of action () and -a -> run action 2 if action 1 ok
	find ${d} \
		# only do on *.js file. .*\(js\|html\|css\|ts\)
		-regex ".*\.\(js\)" \
		# group 1: if exec 1 ok -> do exec 2 else stop when exec 1 not ok
		\( -exec grep -rl "${f}" {} \; -a -exec sed -i -e "s/${f}/${r}/g" {} \; \) \
		# group 2
		\(  -exec grep -rl "${f2}" {} \; -a -exec sed -i -e "s/${f2}/${r2}/g" {} \; \) && \
	# #
	# f="font-src 'self' blob:" && \
	# r="font-src 'self' blob: fonts.gstatic.com" && \
	# # grep -rl "${f}" ${d} | xargs sed -i "s/${f}/${r}/g" && \
	# find ${d} -regex ".*\.\(js\|ts\)" -exec grep -rl "${f}" {} \; -a -exec sed -i "s/${f}/${r}/g" {} \; && \
	#
	# Permission after extract
	chown -R ${MY_USER}:${MY_GROUP} ${MY_APPS}/code-server #ENDRUN


# RUN \
# 	echo "*** Install zsh theme to $HOME directory ***" && \
# 	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
# 	rm -rf ~/.oh-my-zsh/.git* && \
# 	rm -rf ~/.oh-my-zsh/*.md && \
# 	cp ~/.oh-my-zsh/themes/robbyrussell.zsh-theme /tmp/ && \
# 	rm ~/.oh-my-zsh/themes/* && \
# 	mv /tmp/robbyrussell.zsh-theme ~/.oh-my-zsh/themes/ && \
# 	echo "*** change permisson, MY_USER, MY_GROUP was defined in base image ***" &&\
# 	chown -R ${MY_USER}:${MY_GROUP} ~/.oh-my-zsh ~/.zshrc && \
# 	chown ${MY_USER}:${MY_GROUP} ~/.zshrc #ENDRUN

# RUN \
# 	# copy oh-my-zsh from root to user
# 	cp -r /root/.oh-my-zsh /root/.zshrc ${MY_USERMY_HOME_DIR}/ && \
# 	chown -R ${MY_USER}:${MY_GROUP} ${MY_USERMY_HOME_DIR}/.oh-my-zsh && \
# 	chown ${MY_USER}:${MY_GROUP} ${MY_USERMY_HOME_DIR}/.zshrc #ENDRUN






# change all default shell ash to bash
RUN \
	sed 's_\/bin\/ash_\/bin\/bash_g' -i /etc/passwd && \
	# log_title "default zsh shell go ${MY_USER}"
	sed "s/${MY_USER}:\/bin\/bash$/${MY_USER}:\/bin\/zsh/" -i /etc/passwd #ENDRUN
	# OR below for ${MY_USER} only
	# usermod --shell /bin/zsh ${MY_USER} \
	# log_title "setup for auto change to ${MY_USER} when start bash shell"
	# change user on every run bash
	# to prevent run in root user, apply for rootless mode (don't use MY_USER directive in dockerfile)
	# put this file to /etc/profile.d/any_name.sh, remember chown to root and chmod to 400 or 600
	# echo "exec su ${MY_USER}" >> /etc/profile.d/start.sh
	# OR
	# echo "exec su ${MY_USER}" >> /root/.bashrc #ENDRUN

RUN \
	### End of RUN -> cleanup
	rm -rf /tmp/* && \
	rm -rf /var/cache/*
# HERE IS LAST RUN COMMAND, DONT WRITE ENDRUN


EXPOSE 8080

COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh


ENTRYPOINT [ "/scripts/entrypoint.sh" ]
