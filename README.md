# Airflow with Docker
This image builds upon [Puckel's Airflow image](https://github.com/puckel/docker-airflow), specialising it for use as 
controller of tasks being run in standalone Docker containers (using the Python Docker bindings).

It uses a LocalExecutor to allow for task parallelism, doesn't laod the example, and adds a few utilities as well as
localising to South Africa, otherwise the config is left as the defaults.

On the last point, I would be open to a pull request to make this optional as I realise not everyone is lucky enough to
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
2. Now, actually start the airflow container (**NB it's a privileged container**):
  ```bash
  docker run -e POSTGRES_HOST=<State DB host name> \
             -e POSTGRES_PORT=<State DB port number> \
             --name docker-airflow \
             -v /var/run/docker.sock:/var/run/docker.sock:rw \
             -p <Host port for WUI>:8080 \
             -p <Docker API port>:8793 \
             --privileged \
             --restart always \
             -d cityofcapetown/airflow
  ```
 3. Once your airflow container has come up, you should be able to access the UI on the `<Host port for WUI>` specified.

## Adding Dags
The dag files need to be copied to `/usr/local/airflow/dags` inside the container, i.e.
`docker cp <dag file path> docker-airflow:/usr/local/airflow/dags/`.

Or you can add `-v <path on host system to dag directory>:/usr/local/airflow/dags/` to the run command above to map it
to a directory on the host system.