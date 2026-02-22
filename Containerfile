FROM docker.io/library/debian:stable-backports

# Maintainer and image description
LABEL maintainer="Arnulf Heimsbakk <arnulf.heimsbakk@gmail.com>"
LABEL description="Sikkert arbeidsmiljø for opencode med utviklerverktøy"
LABEL version="1.0"

# Build argument to select opencode release (default: latest)
ARG OPENCODE_VERSION="latest"

# Minimal environment variables for non-interactive builds and locales
ENV DEBIAN_FRONTEND="noninteractive"
ENV LANG=nb_NO.UTF-8
ENV HOME=/home/opencode
ENV PATH="/usr/local/bin:$PATH"

# Install required packages in one layer and clean apt cache to reduce image size.
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
      openssh-client \
      pipenv \
      procps \
      pipenv \
      python3-pip \
      python3-wheel \
      python3-wheel-whl \
      ripgrep \
      rsync \
      tmux \
      tree \
      unzip \
      vim \
      zip \
      && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*;

# Enable Norwegian and US locales used in the image
RUN sed -Ei 's/^.*(nb_NO.UTF-8 .*)$/\1/g' /etc/locale.gen && \
    sed -Ei 's/^.*(en_US.UTF-8 .*)$/\1/g' /etc/locale.gen && \
    locale-gen

# Create the opencode home directory and allow access (used by container runtime).
RUN mkdir -p /home/opencode && \
    chmod 777 /home/opencode

# System-wide shell niceties: bash completion and helpful aliases
RUN echo "if [ -f /etc/bash_completion ]; then . /etc/bash_completion; fi" >> /etc/bash.bashrc && \
    echo "alias ls='ls --color=auto'" >> /etc/bash.bashrc && \
    echo "alias grep='grep --color=auto'" >> /etc/bash.bashrc

# Download and install the opencode .deb release matching OPENCODE_VERSION.
# The script chooses latest release or a specific tag and picks the first amd64 .deb.
RUN export VERSION="${OPENCODE_VERSION}" && \
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
    curl -sSL "$DOWNLOAD_URL" -o /tmp/opencode.deb && \
    apt-get update && \
    eatmydata apt-get -y install /tmp/opencode.deb && \
    rm /tmp/opencode.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Installer siste versjon av UV
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Copy and make the container entrypoint script executable
COPY container-init.sh /usr/local/bin/container-init.sh
RUN chmod +x /usr/local/bin/container-init.sh

# Working directory and volumes exposed by the image
WORKDIR /work
VOLUME ["/work", "/home/opencode"]

# Entrypoint runs container-init.sh which prepares the environment and executes CMD
ENTRYPOINT ["/usr/local/bin/container-init.sh"]
CMD ["bash",  "-l", "-c", "/usr/bin/opencode-cli"]
