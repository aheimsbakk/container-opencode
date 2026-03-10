# Stage 1: Acquire the opencode .deb package
# Pass --build-arg INSTALL_SOURCE=local to copy the .deb from the build context
# instead of downloading from GitHub (avoids API rate limiting).
FROM docker.io/library/debian:stable-backports AS downloader

ARG OPENCODE_VERSION="latest"
ARG INSTALL_SOURCE=""

# Always copy the local .deb into the image so it is available regardless of INSTALL_SOURCE.
# When INSTALL_SOURCE != "local" it will simply be ignored in the next step.
COPY opencode-desktop-linux-amd64.deb /tmp/opencode-local.deb

RUN apt-get update && \
    apt-get -y install --no-install-recommends ca-certificates curl jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN if [ "${INSTALL_SOURCE}" = "local" ]; then \
        echo "Using local .deb from build context" && \
        cp /tmp/opencode-local.deb /tmp/opencode.deb; \
    else \
        export VERSION="${OPENCODE_VERSION}" && \
        export REPO="anomalyco/opencode" && \
        if [ "${VERSION}" = "latest" ]; then \
            API_URL="https://api.github.com/repos/${REPO}/releases/latest"; \
        else \
            API_URL="https://api.github.com/repos/${REPO}/releases/tags/${VERSION}"; \
        fi && \
        echo "Fetching release metadata from $API_URL" && \
        DOWNLOAD_URL=$(curl -sSL "${API_URL}" | \
            jq -r '.assets[] | select(.name | endswith(".deb")) | select(.name | contains("amd64")) | .browser_download_url' | head -n 1) && \
        if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then \
            echo "ERROR: No .deb package found for version ${VERSION}"; exit 1; \
        fi && \
        echo "Downloading: $DOWNLOAD_URL" && \
        curl -sSL "$DOWNLOAD_URL" -o /tmp/opencode.deb; \
    fi

# Stage 2: Final image
FROM docker.io/library/debian:stable-backports

ARG OPENCODE_VERSION="latest"

# Maintainer and image description
LABEL maintainer="Arnulf Heimsbakk <arnulf.heimsbakk@gmail.com>"
LABEL description="Sikkert arbeidsmiljø for opencode med utviklerverktøy"
LABEL version="${OPENCODE_VERSION}"

# Minimal environment variables for non-interactive builds and locales
ENV DEBIAN_FRONTEND="noninteractive"
ENV LANG=nb_NO.UTF-8
ENV HOME=/home/opencode
ENV PATH="/usr/local/bin:$PATH"

# Install required packages, configure locales, create home dir, and set up shell niceties — all in one layer
RUN apt-get update && \
    apt-get -y install eatmydata && \
    eatmydata apt-get -y install \
      bash-completion \
      bc \
      ca-certificates \
      curl \
      gh \
      git \
      gnupg \
      iputils-ping \
      jq \
      less \
      locales \
      lsof \
      man-db \
      nano \
      openssh-client \
      pipenv \
      procps \
      python3-pip \
      python3-wheel \
      ripgrep \
      rsync \
      shfmt \
      tmux \
      tree \
      unzip \
      vim \
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

# Copy the pre-downloaded opencode .deb from the downloader stage and install it
COPY --from=downloader /tmp/opencode.deb /tmp/opencode.deb
RUN apt-get update && \
    eatmydata apt-get -y install /tmp/opencode.deb && \
    rm /tmp/opencode.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy and make the container entrypoint script executable
COPY --chmod=755 container-init.sh /usr/local/bin/container-init.sh

# Working directory and volumes exposed by the image
WORKDIR /work
VOLUME ["/work", "/home/opencode"]

# Entrypoint runs container-init.sh which prepares the environment and executes CMD
ENTRYPOINT ["/usr/local/bin/container-init.sh"]
CMD ["bash", "-l", "-c", "/usr/bin/opencode-cli"]
