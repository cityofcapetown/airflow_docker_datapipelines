#!/usr/bin/env bash

echo "> Running helm chart" &&
  sudo KUBECONFIG=/etc/rancher/k3s/k3s.yaml helm upgrade --install airflow2 apache-airflow/airflow \
                                                         --namespace airflow2 --create-namespace \
                                                         --values airflow2-values.yaml &&
  echo "> Creating the secrets" &&
  sudo kubectl apply -f airflow2-secrets.yaml &&
  echo "> Creating the roles" &&
  sudo kubectl apply -f airflow2-roles.yaml &&
  echo "> All done!"
