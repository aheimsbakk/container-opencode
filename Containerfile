FROM docker.io/library/node:26

# Maintainer and image description
LABEL maintainer="Arnulf Heimsbakk <arnulf.heimsbakk@gmail.com>" \
      description="Secure working environment for opencode with developer tools"

# Software versions
ENV UV_VERSION=0.11.26

# Opencode search with Exa
# ENV OPENCODE_ENABLE_EXA=1

# Minimal environment variables for build and environment
ENV DEBIAN_FRONTEND="noninteractive" \
    LANG=nb_NO.UTF-8 \
    LC_ALL=nb_NO.UTF-8 \
    PATH="/usr/local/bin:$PATH" \
    TERM=xterm-256color \
    EDITOR=vim \
    CGO_ENABLED=1

# Install required packages 
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
      bash-completion \
      bc \
      ca-certificates \
      curl \
      file \
      gawk \
      gcc \
      git \
      gnupg \
      golang \
      govulncheck \
      iputils-ping \
      jq \
      less \
      libc6-dev \
      locales \
      lsof \
      man-db \
      nano \
      pipx \
      procps \
      ripgrep \
      rsync \
      shfmt \
      tini \
      tree \
      unzip \
      vim \
      xxd \
      zip \
      && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # Enable Norwegian and US locales
    sed -Ei 's/^.*(nb_NO.UTF-8 .*)$/\1/g' /etc/locale.gen && \
    sed -Ei 's/^.*(en_US.UTF-8 .*)$/\1/g' /etc/locale.gen && \
    locale-gen && \
    # Create the opencode home directory
    mkdir -p /home/opencode && \
    chmod 777 /home/opencode && \
    # System-wide shell niceties
    echo "if [ -f /etc/bash_completion ]; then . /etc/bash_completion; fi" >> /etc/bash.bashrc && \
    echo "alias ls='ls --color=auto'" >> /etc/bash.bashrc && \
    echo "alias grep='grep --color=auto'" >> /etc/bash.bashrc

# Only install packages that have been relased 7 days ago
RUN npm config set min-release-age 7 --global

# Install playwright for use with playwright mcp (browser access)
RUN npx playwright install-deps && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* 

# Init script
ADD container-init.sh /

# Working directory and volumes exposed by the image
WORKDIR /work
VOLUME ["/work", "/home/opencode"]

# Set home to opencode
ENV HOME=/home/opencode

# Execute shell as default
ENTRYPOINT ["/usr/bin/tini", "--", "/container-init.sh"]
CMD ["opencode"]
