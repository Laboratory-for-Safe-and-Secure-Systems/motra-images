FROM debian:bookworm-slim AS builder 

# setup of the base image 
ENV DEBIAN_FRONTEND=noninteractive

ARG USERNAME=motra
ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update && apt-get install \
        -y --no-install-recommends \
        git \
        build-essential debhelper bison check cmake flex groff libbsd-dev \
        libcurl4-openssl-dev libmaxminddb-dev libgtk-3-dev libltdl-dev libluajit-5.1-dev \
        libncurses5-dev libnet1-dev libpcap-dev libpcre2-dev libssl-dev \
        tldr \
        less \
        curl \
        tree \
        sudo \
        unzip \
        python3 \
        python3-pip \
        ca-certificates && \
    # rm -rf /var/lib/apt/lists/* && \
    \
    # Create the non-root user and add to sudo group
    groupadd --gid "$USER_GID" "$USERNAME" && \
    useradd --uid "$USER_UID" --gid "$USER_GID" -m -s /bin/bash "$USERNAME" && \
    \
    # Configure passwordless sudo for the new user
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/"$USERNAME" && \
    chmod 0440 /etc/sudoers.d/"$USERNAME"

WORKDIR /home/$USERNAME
# COPY --chown=$USER_UID:$USER_GID . .
# we run the default example for the device dashboard. We will then try to add 
# some custom logic to this example using some patches or other scripts.
RUN git clone https://github.com/cesanta/mongoose.git

EXPOSE 8000 8443

WORKDIR /home/$USERNAME/mongoose/tutorials/http/device-dashboard
CMD [ "make" ]
