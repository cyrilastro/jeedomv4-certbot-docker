FROM	jeedom/jeedom:latest

# METADATA
LABEL	version="1.0"
LABEL	description="Jeedom from CBA"

ARG NEW_USER
ARG ROOT_PWD

RUN apt-get update -qy && apt-get install -y \
	openssh-server \
	locales \
	ccze \
	nano \
	snapd \
    net-tools \
	build-essential \
	libssl-dev \
	python python-pip python3 python3-venv libaugeas0 \
	apt-utils
RUN apt install -o Dpkg::Options::="--force-confdef" -y chromium
RUN apt install -o Dpkg::Options::="--force-confdef" -y librsync-dev
RUN apt-get remove certbot
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create new user account and elevate to sudo
RUN useradd -s /bin/bash -d /home/${NEW_USER} -m ${NEW_USER} && \
    mkdir /home/${NEW_USER}/.ssh && chown ${NEW_USER}:${NEW_USER} /home/${NEW_USER}/.ssh
RUN echo "${NEW_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/90-mysudoers

# SSH Server for newly created user
RUN mkdir /var/run/sshd
COPY ssh/sshd_config /etc/ssh/
COPY ssh/authorized_keys /home/${NEW_USER}/.ssh/
RUN chmod 600 /home/${NEW_USER}/.ssh/authorized_keys
RUN chown ${NEW_USER}:${NEW_USER} /home/${NEW_USER}/.ssh/authorized_keys
RUN echo "root:${ROOT_PWD}" | chpasswd
#RUN update-rc.d ssh enable && service ssh start

# Install CERTBOT through Python3 pip 
RUN python3 -m venv /opt/certbot/
RUN /opt/certbot/bin/pip install --upgrade pip
RUN /opt/certbot/bin/pip install certbot certbot-apache
RUN ln -s /opt/certbot/bin/certbot /usr/bin/certbot

# Install missing pip2 packages
RUN pip2 install fasteners
RUN pip2 install future

CMD service ssh restart && sh /root/init.sh
