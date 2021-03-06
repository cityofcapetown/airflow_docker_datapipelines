# Airflow with ~~Docker~~ Kubernetes
This image builds upon [Puckel's Airflow image](https://github.com/puckel/docker-airflow), specialising it for use as 
controller of tasks being run ~~standalone Docker containers (using the Python Docker bindings)~~ in a Kubernetes cluster.

Please note the instructions in this README are for launching this Docker image standalone (i.e. non-Kubernetes). Please head over to the [Kubernetes README](./k8s/README.md)
to go on the exciting journey of deploying this container as a service within a Kubernetes cluster (which Airflow will
also use to run tasks).

This airflow configuration uses a LocalExecutor to allow for task parallelism, doesn't load the examples, and adds a few
utilities as well as localising to South Africa, otherwise the config is left to the defaults.

The reason [the **LocalExecutor**](https://airflow.apache.org/_modules/airflow/executors/local_executor.html) is used is that our intended mode of execution is to offload work directly to Docker or Kubernetes, and so avoid the complication of maintaining a separate work broker.

On the timezone point, I would be open to a pull request to make this optional as I realise not everyone is lucky enough to
live in SA.

## Getting Started
1. As a `LocalExecutor` is used, a separate state DB is required. These instructions assume PostgreSQL , i.e.
  ```bash
  docker run -e POSTGRES_PASSWORD=airflow \
             -e POSTGRES_USER=airflow \
             -e POSTGRES_DB=airflow \
             -p <host port for state DB>:5432 \
             --name airflow-postgres \
             -d postgres
  ```
2. Now, actually start the airflow container:
  ```bash
  docker run -e POSTGRES_HOST=<State DB host name> \
             -e POSTGRES_PORT=<State DB port number> \
             --name k8s-airflow \
             -p <Host port for WUI>:8080 \
             --restart always \
             -d cityofcapetown/airflow
  ```
 3. Once your airflow container has come up, you should be able to access the UI on the `<Host port for WUI>` specified.

## Adding Dags
The dag files need to be copied to `/usr/local/airflow/dags` inside the container, i.e.
`docker cp <dag file path> docker-airflow:/usr/local/airflow/dags/`.

Or you can add `-v <path on host system to dag directory>:/usr/local/airflow/dags/` to the run command above to map it
to a directory on the host system.
