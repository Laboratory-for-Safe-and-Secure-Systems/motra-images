FROM debian:bookworm-slim AS builder 

# setup of the base image 
ENV DEBIAN_FRONTEND=noninteractive

ARG USERNAME=milka
ARG USER_UID=1000
ARG USER_GID=1000
ARG USER_PASSWD=ninja

RUN apt-get update && apt-get install \
        -y --no-install-recommends \
        openssh-server \
        tldr \
        less \
        curl \
        tree \
        sudo \
        ca-certificates 
    # rm -rf /var/lib/apt/lists/* && 

# Create the non-root user and add to sudo group
RUN groupadd --gid "$USER_GID" "$USERNAME" && \
    useradd --uid "$USER_UID" --gid "$USER_GID" -m -s /bin/bash "$USERNAME" && \
    echo "$USERNAME:$USER_PASSWD" | chpasswd && \
    echo "$USER_PASSWD" > passwd && \
    service ssh start && \
    \
    # Configure passwordless sudo for the new user
    echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/"$USERNAME" && \
    chmod 0440 /etc/sudoers.d/"$USERNAME"

WORKDIR /home/$USERNAME/motra

EXPOSE 22

WORKDIR /home/$USERNAME/
COPY --from=container_context entrypoint.sh entrypoint.sh

ENV OPENSSH_INSTALL_PATH="/usr"
ENTRYPOINT ["/usr/bin/env"]
CMD ["./entrypoint.sh"]

