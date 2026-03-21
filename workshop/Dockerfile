FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG MAVEN_VERSION=3.9.3
ENV MAVEN_HOME=/opt/maven
ENV PATH="${MAVEN_HOME}/bin:${PATH}"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        gnupg \
        openjdk-17-jdk \
        python3 \
        python3-pip \
        python3-venv \
        tar \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt \
    && curl -fsSL "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
        | tar -xz -C /opt \
    && ln -s "/opt/apache-maven-${MAVEN_VERSION}" "${MAVEN_HOME}"

RUN curl -fL https://install-cli.jfrog.io | sh

RUN useradd --create-home --shell /bin/bash workshop

USER workshop
WORKDIR /home/workshop

CMD ["/bin/bash"]
