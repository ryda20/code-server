
FROM ryda20/alpine:3.16

# defined in base image
# ENV \
# 	# get defined ARG from base image
# 	USER_NAME=${USER_NAME:-stduser} \
# 	GROUP_NAME=${GROUP_NAME:-stduser} \
# 	USER_APP_DIR=${USER_APP_DIR:-/app} \
#	USER_WORKSPACE_DIR=${USER_WORKSPACE_DIR:-/workspace}

ENV \
	# env for this dockerfile
	VERSION=4.7.1 \
	PORT=8080 \
	PROXY_DOMAIN="" \
	PASSWORD=""

# supply your pub key via `--build-arg ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"` when running `docker build`
# 
ARG \
	install_openrc="" \
	install_sshd="" \
	ssh_public_key=""

# RULE TO WRITE RUN COMMAND FOR AUTO GENERATE PRODUCT DOCKERFILE
# AFTER RUN, USING \ TO WRITE CODE IN NEW LINE
# AND THE LAST LINE OF CODE, COMMAND WITH '#ENDRUN'
# EXCEPT FOR THE LAST RUN, DONT WRITE #ENDRUN
RUN \
	if [[ "${install_openrc}" == "yes" ]] ; then \
	echo "### Install OPENRC ###" ; \
	apk add --update --no-cache openrc ; \
	mkdir -p /run/openrc ; \
	# touch softlevel because system was initialized without openrc
	touch /run/openrc/softlevel ; \
	fi #ENDRUN
#
RUN \
	echo "###===> Install dependencies" && \
	apk --no-cache --update add \
	# already add from base image
	# bash \
	zsh \
	curl \
	libc6-compat gcompat \
	# gnupg \
	nodejs \
	# openssh-client \
	# already add from base image
	# shadow \
	#
	#
	### fix ld-linux-x86-64.so.2 not found - comment out because already exist after install libc6-compat and gcompat
	#mkdir /lib64 && 
	#ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
	git #ENDRUN


RUN \	
	echo "###===> Install code-server ${CODE_RELEASE}" && \
	if [ -z ${CODE_RELEASE+x} ]; then \
	CODE_RELEASE=$(curl -sX GET https://api.github.com/repos/coder/code-server/releases/latest | awk '/tag_name/{print $4;exit}' FS='[""]' | sed 's|^v||'); \
	fi && \
	# USER_APP: defined in base image
	mkdir -p ${USER_APP_DIR}/code-server && \
	curl -o /tmp/code-server.tar.gz -L "https://github.com/coder/code-server/releases/download/v${CODE_RELEASE}/code-server-${CODE_RELEASE}-linux-amd64.tar.gz" && \
	tar xf /tmp/code-server.tar.gz -C ${USER_APP_DIR}/code-server --strip-components=1 && \
	#
	echo "remove original node execute file from code-server/lib folder" && \
	rm ${USER_APP_DIR}/code-server/lib/node && \
	#
	### check and remove unuse shortcut
	# remove node shortcut
	# -h determine file is a symbolic link
	if [ -f "${USER_APP_DIR}/code-server/node" ] && [ -h "${USER_APP_DIR}/code-server/node" ] ; then \
	rm ${USER_APP_DIR}/code-server/node ; \
	fi && \
	# remove code-server shortcut
	if [ -f "${USER_APP_DIR}/code-server/code-server" ] && [ -h "${USER_APP_DIR}/code-server/code-server" ] ; then \
	rm ${USER_APP_DIR}/code-server/code-server ; \
	fi && \
	# replace exec path from node to code-server in new path
	sed -i 's+"$ROOT\/lib\/node"+node+g' ${USER_APP_DIR}/code-server/bin/code-server && \
	#
	# Permission after extract
	chown -R ${USER_NAME}:${GROUP_NAME} ${USER_APP_DIR} #ENDRUN


RUN \
	### Install zsh theme to $HOME directory
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
	rm -rf ~/.oh-my-zsh/.git* && \
	rm -rf ~/.oh-my-zsh/*.md && \
	cp ~/.oh-my-zsh/themes/robbyrussell.zsh-theme /tmp/ && \
	rm ~/.oh-my-zsh/themes/* && \
	mv /tmp/robbyrussell.zsh-theme ~/.oh-my-zsh/themes/ && \
	# change permisson, USER_NAME, GROUP_NAME was defined in base image
	chown -R ${USER_NAME}:${GROUP_NAME} ~/.oh-my-zsh ~/.zshrc && \
	chown ${USER_NAME}:${GROUP_NAME} ~/.zshrc #ENDRUN

RUN \
	# copy oh-my-zsh from root to user
	cp -r /root/.oh-my-zsh /root/.zshrc ${USER_HOME_DIR}/ && \
	chown -R ${USER_NAME}:${GROUP_NAME} ${USER_HOME_DIR}/.oh-my-zsh && \
	chown ${USER_NAME}:${GROUP_NAME} ${USER_HOME_DIR}/.zshrc #ENDRUN






RUN \
	if [ "${install_sshd}" == "yes" ] ; then \
	echo "### Install OpenSSH ###" ; \
	apk add --no-cache openssh ; \
	mkdir -p /root/.ssh ; \
	chmod 0700 /root/.ssh ; \
	ssh-keygen -A ; \
	echo -e "PasswordAuthentication no" >> /etc/ssh/sshd_config ; \
	echo "${ssh_public_key}" > /root/.ssh/authorized_keys ; \
	SSHD_INSTALLED=1 ; \
	fi #ENDRUN

# RUN \
# 	# check if use set sudo password
# 	if [ -n "${SUDO_PASSWORD}" ] || [ -n "${SUDO_PASSWORD_HASH}" ]; then \
# 	echo "setting up sudo access" ; \
# 	if ! grep -q '${USER_NAME}' /etc/sudoers; then \
# 	echo "adding ${USER_NAME} to sudoers" ; \
# 	echo "${USER_NAME} ALL=(ALL:ALL) ALL" >> /etc/sudoers ; \
# 	fi && \
# 	if [ -n "${SUDO_PASSWORD_HASH}" ]; then \
# 	echo "setting sudo password using sudo password hash" ; \
# 	sed -i "s|^${USER_NAME}:\!:|${USER_NAME}:${SUDO_PASSWORD_HASH}:|" /etc/shadow ; \
# 	else \
# 	echo "setting sudo password using SUDO_PASSWORD env var" ; \
# 	echo -e "${SUDO_PASSWORD}\n${SUDO_PASSWORD}" | passwd ${USER_NAME} ; \
# 	fi ; \
# 	else \
# 	echo "allow ${USER_NAME} can change his UID/GID only" ; \
# 	# echo -e '${USER_NAME} ALL = (root:root) NOPASSWD: \
# 	# /bin/cat,  \
# 	# /usr/sbin/groupmod -og $EGID ${USER_NAME}, \
# 	# /usr/sbin/groupmod -g 0 ${USER_NAME}, \
# 	# /usr/sbin/groupmod -og 0 ${USER_NAME}, \
# 	# /usr/sbin/usermod -ou $EUID -g $EGID ${USER_NAME}, \
# 	# /usr/sbin/usermod -u 0 -g 0 ${USER_NAME}, \
# 	# /usr/sbin/usermod -ou 0 -g 0 ${USER_NAME}' \
# 	# >> /etc/sudoers ; \
# 	# echo "${USER_NAME} ALL = (root:root) NOPASSWD: /bin/sed -i /etc/passwd -r 's/1000:1000/$PUID:$PGID/g'" >> /etc/sudoers ; \
# 	# marlena ALL = NOPASSWD: /bin/systemctl restart nginx.service
# 	# /bin/cat
# 	# /usr/sbin/groupmod
# 	# /usr/sbin/usermod
# 	fi #ENDRUN

# HERE IS LAST RUN COMMAND, DONT WRITE ENDRUN
# change all default shell ash to bash
RUN \
	sed 's_\/bin\/ash_\/bin\/bash_g' -i /etc/passwd && \
	# log_title "default zsh shell go ${USER_NAME}"
	sed "s/${USER_NAME}:\/bin\/bash$/${USER_NAME}:\/bin\/zsh/" -i /etc/passwd && \
	# log_title "setup for auto change to ${USER_NAME} when start bash shell"
	# change user on every run bash
	# to prevent run in root user, apply for rootless mode (don't use USER directive in dockerfile)
	# put this file to /etc/profile.d/any_name.sh, remember chown to root and chmod to 400 or 600
	# echo "exec su ${USER_NAME}" >> /etc/profile.d/start.sh
	# OR
	echo "exec su ${USER_NAME}" >> /root/.bashrc #ENDRUN

RUN \
	### End of RUN -> cleanup
	rm -rf /tmp/* && \
	rm -rf /var/cache/*



EXPOSE 8080

COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

# CMD ["/usr/sbin/sshd","-D"]
