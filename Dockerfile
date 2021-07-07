# Copyright 2021, Edson Ramiro Lucas Filho <edson.lucas@uni-passau.de>
# SPDX-License-Identifier: GPL-2.0-only

FROM ubuntu:21.04

MAINTAINER Edson Ramiro Lucas Filho "edson.lucas@uni-passau.de"

ENV DEBIAN_FRONTEND noninteractive
ENV LANG="C.UTF-8"
ENV LC_ALL="C.UTF-8"

# change root password
RUN echo 'root:root' | chpasswd

# Install Linux required packages
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update &&\
    apt-get -y dist-upgrade &&\
    apt-get install -y --no-install-recommends \
        apt-utils \
        build-essential \
        default-jdk \
        default-jre \
        git \
        gnupg2 \
        less \
        maven \
        npm \
        openssh-client\
        sudo \
        time \
        vim \
        wget

# Create and Configure metanome user
RUN useradd -m -G sudo -s /bin/bash metanome && echo "metanome:metanome" | chpasswd
RUN echo "%sudo   ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN echo "PATH=\"${PATH}:/usr/lib/jvm/default-java/bin/\"" >> /home/metanome/.bashrc

# Download and Compile Metanome
USER metanome
WORKDIR /home/metanome/

# Upgrade npm before compiling
RUN sudo npm install -g npm

#################################################################
# Download Metanome
RUN git clone https://github.com/HPI-Information-Systems/Metanome.git metanome
WORKDIR /home/metanome/metanome/

# Update Submodules
RUN git submodule init
RUN git submodule update

# Build Metanome in parallel
RUN mvn -T 1C clean install -DskipTests=true

#################################################################
# Download and Compile Metanome algorithms
WORKDIR /home/metanome/
RUN git clone https://github.com/HPI-Information-Systems/metanome-algorithms.git
WORKDIR metanome-algorithms/

# Build
RUN MAVEN_OPTS="-Xmx1g -Xms20m -Xss10m" mvn clean install

# Leave bash at $HOME
WORKDIR /home/metanome/
CMD /bin/bash
