FROM debian:bookworm-slim AS builder 

# setup of the base image 
ENV DEBIAN_FRONTEND=noninteractive


RUN apt-get update && apt-get install \
        -y --no-install-recommends \
        libssl-dev \
        gcc g++ gdb cpp \
        make cmake \
        libtool \
        libc6 \
        autoconf automake pkg-config \
        build-essential \
        libzstd1 zlib1g \
        libssh-4 libssh-dev libssl3 \
        libc6-dev libc6 \
        libcrypt-dev \
        gettext \
        tldr \
        less \
        curl \
        tree \
        sudo \
        ca-certificates 
    # rm -rf /var/lib/apt/lists/* && 

ARG USERNAME=motra
ARG USER_UID=1000
ARG USER_GID=1000
ARG CRED=biggles

# Create the non-root user and add to sudo group
# the sshd username is required for sshd to run, otherwise startup will fail!
# pick some random id for sshd, otherwise downstream commands might fail
RUN useradd --uid 55555 -s /bin/bash "sshd" && \
    groupadd --gid "$USER_GID" "$USERNAME" && \
    useradd --uid "$USER_UID" --gid "$USER_GID" -m -s /bin/bash "$USERNAME" && \
    echo "$USERNAME:$CRED" | chpasswd && \
    # store the data in plain text when testing
    echo "$CRED" > passwd && \
    \
    # Configure passwordless sudo for the new user
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/"$USERNAME" && \
    chmod 0440 /etc/sudoers.d/"$USERNAME"

WORKDIR /home/$USERNAME/

# https://gist.github.com/jtmoon79/745e6df63dd14b9f2d17a662179e953a#build
ARG OPENSSH_VER=9.1p1
RUN curl -sLO "https://ftp.hostserver.de/pub/OpenBSD/OpenSSH/portable/openssh-$OPENSSH_VER.tar.gz" && \
    tar -xzf openssh-$OPENSSH_VER.tar.gz && \
    cd openssh-${OPENSSH_VER} && \
    autoconf && \
    ./configure --prefix=/opt/openssh-${OPENSSH_VER} && \
    make && \
    make install 

# configure server options 
#RUN  sed -i.bak 's/^#LogLevel INFO$/LogLevel DEBUG3/' /opt/openssh-${OPENSSH_VER}/etc/sshd_config


# create aliases to use the client side tools inside the container
RUN /bin/bash -c "echo $' \n\
	alias scp=/opt/openssh-${OPENSSH_VER}/bin/scp \n\
	alias scp=/opt/openssh-${OPENSSH_VER}/bin/ssh \n\
	alias scp=/opt/openssh-${OPENSSH_VER}/bin/ssh-agent \n\
	alias scp=/opt/openssh-${OPENSSH_VER}/bin/sftp \n\
	alias scp=/opt/openssh-${OPENSSH_VER}/sbin/sshd ' >> /root/.bashrc "

EXPOSE 22
ENV OPENSSH_INSTALL_PATH="/opt/openssh-${OPENSSH_VER}"
SHELL [ "${OPENSSH_INSTALL_PATH}/sbin/sshd" , "-D" , "-e" ]

