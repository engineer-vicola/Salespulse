from datetime import datetime

from airflow import DAG
from Airflow.dags.sales_transaction import get_transaction
from Airflow.date_utils import date_str
from airflow.operators.python import PythonOperator
from airflow.providers.amazon.aws.transfers.s3_to_redshift import \
    S3ToRedshiftOperator
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

new_date = date_str
S3_BUCKET = "sales-project"
S3_KEY = f"new_transaction_folder/{new_date}_data_file.parquet"
REDSHIFT_SCHEMA = "public"
REDSHIFT_TABLE = "transactions"
REDSHIFT_CONN_ID = "redshift"
AWS_CONN_ID = "aws_default"


default_args = {
    'owner': 'Data Engineering Team',
    'retries': 1
}

dag = DAG(
    dag_id="transaction_job",
    description="Simulates and loads transactional data to Redshift daily",
    default_args=default_args,
    schedule_interval="0 8 * * *",
    start_date=datetime(2025, 7, 22),
    catchup=False
)

get_transaction_data = PythonOperator(
    task_id="get_transaction_data",
    python_callable=get_transaction,
    dag=dag
)

execute_query = SQLExecuteQueryOperator(
    task_id="execute_query",
    conn_id=REDSHIFT_CONN_ID,
    database="new_redshift_salesdb",
    sql="./sql/create_table.sql",
    split_statements=True,
    return_last=False,
)

s3_to_redshift = S3ToRedshiftOperator(
    task_id="s3_to_redshift",
    schema=REDSHIFT_SCHEMA,
    table=REDSHIFT_TABLE,
    s3_bucket=S3_BUCKET,
    s3_key=S3_KEY,
    copy_options=["FORMAT AS PARQUET"],
    redshift_conn_id=REDSHIFT_CONN_ID,
    aws_conn_id=AWS_CONN_ID,
    dag=dag
)

get_transaction_data >> execute_query >> s3_to_redshift
