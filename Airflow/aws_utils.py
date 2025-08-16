import boto3
from airflow.models import Variable


def new_session():
    boto3.session.Session(
          aws_access_key_id=Variable.get("AWS_ACCESS_KEY_ID"),
          aws_secret_access_key=Variable.get("AWS_SECRET_ACCESS_KEY"),
          region_name=Variable.get("REGION_NAME")
          )
