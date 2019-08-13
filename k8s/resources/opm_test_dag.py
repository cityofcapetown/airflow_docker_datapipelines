from airflow.contrib.operators.kubernetes_pod_operator import KubernetesPodOperator
from airflow.operators.dummy_operator import DummyOperator

from airflow import DAG

from datetime import datetime, timedelta
import uuid
import pprint

DAG_STARTDATE = datetime(2019, 7, 22, 00)
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': DAG_STARTDATE,
    'email': ['gordon.inggs@capetown.gov.za'],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

dag_interval = timedelta(minutes=10)
dag = DAG('opm-test-pipeline',
          catchup=False,
          default_args=default_args,
          schedule_interval=dag_interval,
          concurrency=2)


start = DummyOperator(task_id='run_this_first', dag=dag)

TEST_TASK = 'task'
k1 = KubernetesPodOperator(namespace='airflow-workers',
                          image="ubuntu:18.04",
                          cmds=["bash", "-cx"],
                          arguments=[f"echo {str(uuid.uuid4())} && cat /etc/*release && sleep 30"],
                          name="should-run",
                          task_id=TEST_TASK,
                          is_delete_operator_pod=True,
                          get_logs=True,
                          dag=dag,
                          in_cluster=True,
                          )

TEST_TASK2 = 'task2'
k2 = KubernetesPodOperator(namespace='default',
                          image="ubuntu:18.04",
                          cmds=["bash", "-cx"],
                          arguments=[f"echo {str(uuid.uuid4())} && cat /etc/*release && sleep 30"],
                          name="shouldnt-run",
                          task_id=TEST_TASK2,
                          is_delete_operator_pod=True,
                          get_logs=True,
                          dag=dag,
                          in_cluster=True,
                          )

k1 << start
k2 << start
