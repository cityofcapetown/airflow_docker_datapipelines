# Airflow on/with Kubernetes
These instructions document how to deploy the Airflow Dockerfile in the
root repo to a Kubernetes cluster. Airflow can then also use the same
Kubernetes cluster to run work via the 
[KubernetesPodOperator](https://airflow.readthedocs.io/en/stable/kubernetes.html#kubernetes-operator).

**NB** This doesn't describe how to setup the 
[KubernetesExecutor](https://airflow.readthedocs.io/en/stable/kubernetes.html#kubernetes-executor),
which creates pods to execute other types of operators (e.g. Bash, Python).

Something that is not immediately clear in the documentation is that the KubernetesExecutor is not necessary to use 
airflow to schedule the orchestration of pods in a kubernetes cluster. 

## Assumptions
* Kubernetes is up and running (`systemctl status kubelet` / `systemctl status k3s`)
* You have `kubectl` installed and talking to the cluster
* You are running these commands in this directory
* You're using traefik as your frontend service reverse proxy

## Automagic setup
[This script](./deploy-airflow.sh) executes steps 1-3 without intervention, bringing up everything in the `airflow2` 
namespace, but **cave emptor** - it assumes everything above. It is almost certainly 
a better idea to manually work through the instructions below.

## 1. Helm Cart
Using the official helm chart for airflow, with our values overriding the
configuration: `helm upgrade --install airflow2 apache-airflow/airflow --namespace airflow2 --create-namespace --debug --values ./resources/airflow2-values.yaml`

4 containers at minimum (`scheduler`, `webserver`, `triggerer` and `postgres`) will take several 
minutes to come up. Use `kubectl get pods --namespace airflow2` to check
on the pods' statuses. They should look something like this:

```
NAME                                  READY   STATUS    RESTARTS   AGE
airflow2-scheduler-0                  3/3     Running   101        2d1h
airflow2-postgresql-0                 1/1     Running   0          122m
airflow2-triggerer-ff5c779cb-fbpdq    2/2     Running   1          158m
airflow2-webserver-5666578fd6-5cwm8   1/1     Running   0          88m
airflow2-webserver-5666578fd6-96pps   1/1     Running   0          87m
```

Provided all goes according to plan, the Airflow WUI should be up at 
`<Traffic address>/airflow`.

If you need to roll-back: `helm del --purge airflow2`.

## 2. Secrets
**NB** For obvious reason, the secrets file isn't in this repo.

Deploy the secrets: `kubectl apply -f resources/airflow2-secrets.yaml`

## 3. Roles
Because we're running the airflow worker pods in their own namespace, we need to deploy roles that allow it to work with 
pods in that namespace: `kubectl apply -f resources/airflow2-roles.yaml`

### Checking that Airflow is working correctly
By default, the dags in the [`v2` branch of our airflow dags](https://ds1.capetown.gov.za/ds_gitlab/OPM/airflow-dags/tree/v2)
will sync to the Airflow.

Amongst the dags should be [the test dag from `pipeline-utils`](https://ds1.capetown.gov.za/ds_gitlab/OPM/pipeline-utils/blob/master/dags/opm-test-dag.py).
This dag is comprised of three tasks, each testing different elements of the setup.

Symptom translation:
* **None of the tasks are running**: the scheduler is unhappy. Inspect its
logs.
* **Only one of the tasks are running (`run_this_first`)**: Your scheduler can't
talk to Kubernetes. Maybe you've locked down the API?
* **Only two of the three tasks are running (`run_this_first` and `opm-test-dag.always_works`)**: Congratulations,
everything is working as it should. `opm-test-dag.always_fails` is failing because it is  trying to launch into the 
* default namespace.
* **All three tasks are running!**: Oh dear, this means that airflow can run pods willy-nilly. This probably means your 
permissions have been overly relaxed.
