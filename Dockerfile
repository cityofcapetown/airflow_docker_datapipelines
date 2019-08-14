FROM docker.io/puckel/docker-airflow

LABEL authors="Gordon Inggs and Riaz Arbi"

# Changing back to root
USER root
RUN echo AIRFLOW_VERSION
ARG AIRFLOW_VERSION=1.10.3

# Adding utility packages
RUN set -ex && \
  apt-get update -yqq && \
  apt-get upgrade -yqq && \
  apt-get install -yqq \
  apt-utils 

# Setting the timezone
ENV TZ "Africa/Johannesburg"
RUN echo $TZ > /etc/timezone && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata && \
  rm /etc/localtime && \
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
  dpkg-reconfigure -f noninteractive tzdata

ENV AIRFLOW__CORE__DEFAULT_TIMEZONE "Africa/Johannesburg"

# Define en_ZA
RUN DEBIAN_FRONTEND=noninteractive \
  sed --in-place '/en_ZA.UTF-8/s/^# //' /etc/locale.gen && \
  locale-gen en_ZA && \
  locale-gen en_ZA.UTF-8 && \
  dpkg-reconfigure --frontend=noninteractive locales && \
  update-locale

ENV LANGUAGE en_ZA.UTF-8
ENV LANG en_ZA.UTF-8
ENV LC_ALL en_ZA.UTF-8
ENV LC_CTYPE en_ZA.UTF-8
ENV LC_MESSAGES en_ZA.UTF-8

# Installing kubernetes-specific python packages
RUN pip install apache-airflow[kubernetes]==${AIRFLOW_VERSION} \
    && pip install flask_bcrypt \
    && pip install Flask-OAuthlib

# Changing back to the airflow user
USER airflow

# Unload examples
ENV LOAD_EX "n"
