# Airflow with Docker
This image builds upon [Puckel's Airflow image](https://github.com/puckel/docker-airflow), specialising it for use as 
controller of tasks being run in standalone Docker containers (using the Python Docker bindings).

It starts a LocalExecutor to allow for task parallelism, as well adding a few utilities and localises to South Africa.

As a LocalExecutor is used, a separate Postgret DB is required, i.e.
```bash
docker run -e POSTGRES_PASSWORD=airflow \
           -e POSTGRES_USER=airflow \
           -e POSTGRES_DB=airflow \
           -p <host port>:5432 \
           --name airflow-postgres \
           -d postgres
```

The `POSTGRES_HOST` and `POSTGRES_PORT` variables for the airflow container then need to be set.