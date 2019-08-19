#!/usr/bin/env bash

echo "> Creating airflow Namespaces" &&
  kubectl apply -f resources/airflow_namespaces.yaml &&
  echo "> Creating the airflow executor role" &&
  kubectl apply -f resources/airflow_role.yaml &&
  echo "> Binding the role to airflow system account" &&
  kubectl apply -f resources/airflow_role_bind.yaml &&
  echo "> Creating 'dags' and 'logs' persistent volume claims" &&
  kubectl apply -f resources/airflow_volume_claims.yaml &&
  echo "> Generating a strong fernet key" &&
  sed -in 's/.*fernetKey: "".*/  fernetKey: "'"$(openssl rand -base64 32 | tr -d "\n")"'"/' resources/airflow-values.yaml &&
  echo "> Deploying Airflow via Helm" &&
  helm upgrade --install --values resources/airflow-values.yaml --namespace airflow airflow stable/airflow &&
  echo "> I'm all done, exiting..."
