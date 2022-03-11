FROM apache/airflow:2.2.3-python3.8

# Change container image to root user to allow for global
# installation of software
USER root
RUN apt-get update && apt-get install -y git \
    && pip3 install --upgrade pip && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install dependencies needed for OpenID connect authentication.
# These pip, requests, and flasks-oidc. The packages are installed
# within the user context.
USER airflow
COPY k8s/requirements.txt /requirements.txt
RUN pip3 install -r /requirements.txt

# Copy the OIDC webserver_config.py into the container's $AIRFLOW_HOME
COPY k8s/webserver_config.py $AIRFLOW_HOME/webserver_config.py