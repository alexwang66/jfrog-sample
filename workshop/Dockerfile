FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV MAVEN_VERSION=3.9.3
ENV GRADLE_VERSION=8.7
ENV MAVEN_HOME=/opt/maven
ENV GRADLE_HOME=/opt/gradle

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    python3 \
    python3-pip \
    python3-venv \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js + npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install Maven 3.9.3
RUN mkdir -p /opt && \
    curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    | tar -xz -C /opt && \
    ln -s /opt/apache-maven-${MAVEN_VERSION} ${MAVEN_HOME}

ENV PATH=$PATH:${MAVEN_HOME}/bin

# Install Gradle
# RUN curl -fsSL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o gradle.zip && \
#     unzip gradle.zip -d /opt && \
#     ln -s /opt/gradle-${GRADLE_VERSION} ${GRADLE_HOME} && \
#     rm gradle.zip

ENV PATH=$PATH:${GRADLE_HOME}/bin

# Install JFrog CLI
RUN curl -fL https://install-cli.jfrog.io | sh

# Create workshop user
RUN useradd -ms /bin/bash workshop
USER workshop
WORKDIR /home/workshop

CMD ["/bin/bash"]