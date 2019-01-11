FROM docker.io/puckel/docker-airflow

LABEL authors="Gordon Inggs"

# Changing back to root to install a few things
USER root

# Utility packages
RUN set -ex && \
  apt-get update -yqq && \
  apt-get upgrade -yqq && \
  apt-get install -yqq \
  vim \
  nano \
  htop \
  bash \
  wget \
  apt-utils \
  git \
  sudo

# Installing Docker Python bindings
RUN DEBIAN_FRONTEND=noninteractive \
  pip3 install docker

# Setting the timezone
ENV TZ="Africa/Johannesburg"
RUN echo $TZ > /etc/timezone && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata && \
  rm /etc/localtime && \
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
  dpkg-reconfigure -f noninteractive tzdata

# Define en_ZA
RUN DEBIAN_FRONTEND=noninteractive \
  locale-gen en_ZA && \
  locale-gen en_ZA.UTF-8 && \
  update-locale

ENV LANGUAGE en_ZA.UTF-8
ENV LANG en_ZA.UTF-8
ENV LC_ALL en_ZA.UTF-8
ENV LC_CTYPE en_ZA.UTF-8
ENV LC_MESSAGES en_ZA.UTF-8

# Changing back to the airflow user
USER airflow