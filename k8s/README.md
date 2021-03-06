# Airflow on/with Kubernetes
These instructions document how to deploy the Airflow Dockerfile in the
root repo to a Kubernetes cluster. Airflow can then also use the same
Kubernetes cluster to run work via the 
[KubernetesPodOperator](https://airflow.readthedocs.io/en/stable/kubernetes.html#kubernetes-operator).

**NB** This doesn't describe how to setup the 
[KubernetesExecutor](https://airflow.readthedocs.io/en/stable/kubernetes.html#kubernetes-executor),
which creates pods to execute other types of operators (e.g. Bash, Python).

Something that is not immediately clear in the documentation is that the KubernetesExecutor is not necessary to use airflow to schedule the orchestration of pods in a kubernetes cluster. 

## Assumptions
* Kubernetes is up and running (`systemctl status kubelet`)
* You have `kubectl` installed and talking to the cluster
* You are running these commands in this directory
* You're using a NFS storage client with `StorageClassName='nfs-client'`
* You're using traefik as your frontend service reverse proxy

## 1. Namespace and Role
First up, we need to handle the permissions end of things.

1. Creating the namespaces, `airflow` (where the service will live), and
`airflow-workers` (where the KubernetesPodOperator's pods will live, 
albeit briefly): `kubectl apply -f resources/airflow_namespaces.yaml`

Result:
```
namespace/airflow-workers created
namespace/airflow created
```

2. Creating the Role, `airflow-role`. This role gives permission to mess 
with pods in the `airflow-workers` namespace: `kubectl apply -f resources/airflow_role.yaml`

Result:
```
role.rbac.authorization.k8s.io/airflow-role created
```

3. Binding the Role, `airflow-role`, to the `airflow` service account 
(which doesn't exist yet): `kubectl apply -f resources/airflow_role_bind.yaml`

Result:
```
rolebinding.rbac.authorization.k8s.io/airflow-role-bind created
```

The idea is that the airflow service account can **only** control pods
in the `airflow-workers` namespace. This means even if Airflow gains
sentience, goes rogue and tries to kill us all, it can only do so in the
`airflow-workers` namespace.

## 2. DAG and Log Persistence
When deploying Airflow as a service, the `dags` and `logs` directories
need to be shared between the various component pods. It is also
desirable that these directories are persistence, so that worst comes to
worst, you can rebuild without too much loss of state.

You **can optionally** do this:

* Creating persistent volumes. You want to do this is if you want 
control of exactly where your `dags` and `logs` directories live.
Command: `kubectl apply -f resources/airflow_volumes.yaml`.

**NB** Your NFS configuration is almost certainly different to ours. 
You are probably going to have to change the `nfs.server` and `nfs.path`
keys.

**NBx2** if you decide to go with the above, you probably want to think 
carefully about why you want such fine-grained control of where your 
`dags` and `logs` volumes are ending up.

You **have** to do this:

* Creating persistent volume claims. You want to do this so that your
`dags` and `logs` directories persist between airflow deployments:
`kubectl apply -f resources/airflow_volume_claims.yaml`

Result:
```
persistentvolumeclaim/airflow-dags created
persistentvolumeclaim/airflow-logs created
```

## 3. Setting Values
There isn't anything to do here, other than review and change some of
the values as required in [the supplied file](./resources/airflow-values.yaml).

You really should generate a new fernet key for security purposes. You only 
need to change the others if you want to deviate from our defaults:

* `airflow.fernetKey` - generate something strong for this, using 
`echo $(openssl rand -hex 32)`
* `ingress.web.path` - change this to whatever path you would like 
airflow to be served in traefik.
* `postgres.*` vs `redis.*` - these control the backend used.
* `workers.enabled` - enable this if you want persistent workers, which
is not what we're doing here.

## 4. Applying Helm Chart
Using the helm stable chart for airflow, with our values overriding the
configuration: `helm upgrade --install --values resources/airflow-values.yaml --namespace airflow airflow stable/airflow`

Result:
```
Release "airflow" does not exist. Installing it now.
2019/08/14 02:53:29 Warning: Merging destination map for chart 'airflow'. The destination item 'annotations' is a table and ignoring the source 'annotations' as it has a non-table value of: <nil>
NAME:   airflow
LAST DEPLOYED: Wed Aug 14 01:44:55 2019
NAMESPACE: airflow
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME                DATA  AGE
airflow-env         20    <invalid>
airflow-git-clone   1     <invalid>
airflow-postgresql  0     <invalid>
airflow-scripts     1     <invalid>

==> v1/Deployment
NAME               READY  UP-TO-DATE  AVAILABLE  AGE
airflow-scheduler  0/1    1           0          <invalid>
airflow-web        0/1    1           0          <invalid>

==> v1/PersistentVolumeClaim
NAME                STATUS  VOLUME                                    CAPACITY  ACCESS MODES  STORAGECLASS  AGE
airflow-postgresql  Bound   pvc-18f4450f-affe-4a84-bdcf-2d1f90d5fe94  8Gi       RWO           nfs-client    <invalid>

==> v1/Pod(related)
NAME                                READY  STATUS             RESTARTS  AGE
airflow-postgresql-bdcb64f8d-2x96k  0/1    ContainerCreating  0         <invalid>
airflow-scheduler-6c59ccf94b-vnwfj  0/1    ContainerCreating  0         <invalid>
airflow-web-67fc5d65b-bsnjg         0/1    ContainerCreating  0         <invalid>

==> v1/Secret
NAME                TYPE    DATA  AGE
airflow-postgresql  Opaque  1     <invalid>

==> v1/Service
NAME                TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)   AGE
airflow-postgresql  ClusterIP  10.107.163.8    <none>       5432/TCP  <invalid>
airflow-web         ClusterIP  10.101.175.175  <none>       8080/TCP  <invalid>

==> v1/ServiceAccount
NAME     SECRETS  AGE
airflow  1        <invalid>

==> v1beta1/Deployment
NAME                READY  UP-TO-DATE  AVAILABLE  AGE
airflow-postgresql  0/1    1           0          <invalid>

==> v1beta1/Ingress
NAME         HOSTS  ADDRESS  PORTS  AGE
airflow-web  *      80       <invalid>

==> v1beta1/PodDisruptionBudget
NAME         MIN AVAILABLE  MAX UNAVAILABLE  ALLOWED DISRUPTIONS  AGE
airflow-pdb  N/A            1                0                    <invalid>

==> v1beta1/Role
NAME     AGE
airflow  <invalid>

==> v1beta1/RoleBinding
NAME     AGE
airflow  <invalid>


NOTES:
Congratulations. You have just deployed Apache Airflow
URL to Airflow and Flower:

    - Web UI: http:///airflow/
    - Flower: http:///
```

The 3 containers (`scheduler`, `web` and `postgres`) will take several 
minutes to come up. Use `kubectl get pods --namespace airflow` to check
on the pods' statuses. They should look something like this:

```
NAME                                 READY   STATUS    RESTARTS   AGE
airflow-postgresql-bdcb64f8d-2x96k   1/1     Running   0          3m45s
airflow-scheduler-6c59ccf94b-vnwfj   1/1     Running   0          3m45s
airflow-web-67fc5d65b-bsnjg          1/1     Running   0          3m45s
```

Provided all goes according to plan, the Airflow WUI should be up at 
`<Traffic address>/airflow`.

If you need to roll-back: `helm del --purge airflow`. 

**NB** this won't delete the contents of the `dags` and `logs` dirs, 
thanks to the PVCs created in step (2). Aren't you glad that we did?

## 5. Testing
### Copying the DAG in
Copy the [test dag](./resources/opm_test_dag.py) into the `dags` PVC. 
Use `kubectl get pvc --namespace airflow airflow-dags` to get the volume
which is bound/serving/linking the PVC.

Result:
```
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
airflow-dags   Bound    pvc-2c518c23-3bb5-4a91-9991-b9c737f8655e   1Gi        RWX            nfs-client     21m
```

Using NFS, then the copy command is:
`cp resources/opm_test_dag.py <path to NFS share>/airflow-airflow-dags-<PVC volume name>`,
i.e. `cp resources/opm_test_dag.py /data/nfs/airflow-airflow-dags-pvc-2c518c23-3bb5-4a91-9991-b9c737f8655e`.

If you created explicit volumes earlier, the command would be 
`cp resources/opm_test_dag.py /data/nfs/airflow-dags/`.

And voila, the dag should appear in the WUI, ready to be triggered. This
might take a few minutes.

### Checking that the dag is working
By default, the dag is comprised of three tasks, each testing different
elements of the setup.

Symptom translation:
* **None of the tasks are running**: the scheduler is unhappy. Inspect its
logs.
* **Only one of the tasks are running (`run_this_first`)**: Your scheduler can't
talk to Kubernetes. Maybe you've locked down the API?
* **Only two of the three tasks are running (`run_this_first` and `task`)**: Congratulations,
everything is working as it should. `task2` is failing because it is 
trying to launch into the default namespace.
* **All three tasks are running!**: Oh dear, this means that airflow can
run pods willy-nilly. This probably means your permissions have been overly
relaxed.

## 6. Turning on Basic Auth for the WUI (Optional)
If you're exposing airflow to your whole organisation, you probably want
to restrict access to the WUI.

In `airflow-values.yaml`, pass in configuration to turn on 
authentication and set the backend, i.e.
```yaml
airflow:
  config:
    AIRFLOW__WEBSERVER__AUTHENTICATE: True
    AIRFLOW__WEBSERVER__AUTH_BACKEND: "airflow.contrib.auth.backends.password_auth"
```

After you deploy, when navigating to the WUI, you should be greeted by a
login page demanding credentials.

To generate a user, you will need to run commands on one of the airflow 
containers directly (so as to inject values into the DB directly). The
script [airflow_basic_auth_create_user.py](./resources/airflow_basic_auth_create_user.py)
creates such a user. I will leave it as an exercise to the reader as how
to get that script into the container (probably easiest to smuggle it
in via the DAG PVC).


Script use: 
1. Set the SQL Alchemy Env variable: `export AIRFLOW__CORE__SQL_ALCHEMY_CONN=postgresql+psycopg2://postgres:airflow@"$AIRFLOW_POSTGRESQL_SERVICE_HOST":"$AIRFLOW_POSTGRESQL_SERVICE_PORT"/airflow`
2. Run the script: `python airflow_basic_auth_create_user.py <username> <user email> <password>`

Result:
```
[2019-08-14 21:39:09,695] {{settings.py:182}} INFO - settings.configure_orm(): U
sing pool settings. pool_size=5, pool_recycle=1800, pid=423                     
/usr/local/lib/python3.7/site-packages/psycopg2/__init__.py:144: UserWarning: Th
e psycopg2 wheel package will be renamed from release 2.8; in order to keep inst
alling from binary please use "pip install psycopg2-binary" instead. For details
 see: <http://initd.org/psycopg/docs/install.html#binary-install-from-pypi>.    
  """) 
```

And you should be able to log in with the creds created.
