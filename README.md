# Airflow with ~~Docker~~ Kubernetes
This image used builds upon [Apache's Official Airflow image](https://github.com/apache/airflow), specialising it 
for use as controller of tasks being run in the City of Cape Town's Kubernetes cluster.

Please head over to the [Kubernetes README](./k8s/README.md) to go on the exciting journey of deploying Airflow as a 
service within the City's Kubernetes cluster (which Airflow will also use to run tasks).

This airflow configuration uses a LocalExecutor to allow for task parallelism, doesn't load the examples, and adds a few
utilities as well as localising to South Africa, otherwise the config is left to the defaults.

The reason [the **LocalExecutor**](https://airflow.apache.org/_modules/airflow/executors/local_executor.html) is used is 
that our intended mode of execution is to offload work directly to Kubernetes, and so avoid the complication of 
maintaining a separate work broker.
