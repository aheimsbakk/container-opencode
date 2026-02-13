FROM docker.io/library/debian:stable-backports

LABEL maintainer="Arnulf Heimsbakk <arnulf.heimsbakk@gmail.com>"
LABEL description="Sikkert arbeidsmiljø for opencode med utviklerverktøy"
LABEL version="1.0"

ARG OPENCODE_VERSION="latest"

ENV DEBIAN_FRONTEND="noninteractive"
ENV LANG=nb_NO.UTF-8
ENV HOME=/home/opencode
ENV PATH="/usr/local/bin:$PATH"

RUN apt-get update && \
    apt-get -y install eatmydata && \
    eatmydata apt-get -y install \
      bash-completion \
      ca-certificates \
      curl \
      gh \
      git \
      gnupg \
      iputils-ping \
      jq \
      less \
      locales \
      man-db \
      openssh-client \
      procps \
      rsync \
      tmux \
      tree \
      unzip \
      vim \
      zip \
      && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN sed -Ei 's/^.*(nb_NO.UTF-8 .*)$/\1/g' /etc/locale.gen && \
    sed -Ei 's/^.*(en_US.UTF-8 .*)$/\1/g' /etc/locale.gen && \
    locale-gen

RUN mkdir -p /home/opencode && \
    chmod 777 /home/opencode

RUN echo "if [ -f /etc/bash_completion ]; then . /etc/bash_completion; fi" >> /etc/bash.bashrc && \
    echo "alias ls='ls --color=auto'" >> /etc/bash.bashrc && \
    echo "alias grep='grep --color=auto'" >> /etc/bash.bashrc


RUN export VERSION="${OPENCODE_VERSION}" && \
    export REPO="anomalyco/opencode" && \
    # 1. Bestem API URL basert på om vi skal ha latest eller en spesifikk tag
    if [ "${VERSION}" = "latest" ]; then \
        API_URL="https://api.github.com/repos/${REPO}/releases/latest"; \
    else \
        API_URL="https://api.github.com/repos/${REPO}/releases/tags/${VERSION}"; \
    fi && \
    echo "Henter metadata fra $API_URL" && \
    # 2. Bruk jq for å finne URL til .deb-filen for amd64
    # Vi ser etter en fil som slutter på .deb og inneholder 'amd64'
    DOWNLOAD_URL=$(curl -sSL "${API_URL}" | \
        jq -r '.assets[] | select(.name | endswith(".deb")) | select(.name | contains("amd64")) | .browser_download_url' | head -n 1) && \
    # 3. Sjekk at vi faktisk fant en URL
    if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then \
        echo "FEIL: Fant ingen .deb pakke for versjon ${VERSION}"; exit 1; \
    fi && \
    echo "Laster ned: $DOWNLOAD_URL" && \
    curl -sSL "$DOWNLOAD_URL" -o /tmp/opencode.deb && \
    # 4. Installer pakken og dens avhengigheter
    apt-get update && \
    apt-get -y install /tmp/opencode.deb && \
    # 5. Rydd opp
    rm /tmp/opencode.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY container-init.sh /usr/local/bin/container-init.sh
RUN chmod +x /usr/local/bin/container-init.sh

WORKDIR /work
VOLUME ["/work", "/home/opencode"]

ENTRYPOINT ["/usr/local/bin/container-init.sh"]
CMD ["/usr/bin/opencode-cli"]