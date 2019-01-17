# Airflow with Docker
This image builds upon [Puckel's Airflow image](https://github.com/puckel/docker-airflow), specialising it for use as 
controller of tasks being run in standalone Docker containers (using the Python Docker bindings).

It starts a LocalExecutor to allow for task parallelism, as well adding a few utilities and localises to South Africa.