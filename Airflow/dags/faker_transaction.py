import random as rd
from datetime import datetime
from random import randint

import awswrangler as wr
import boto3
import pandas as pd
from airflow.models import Variable
from faker import Faker

# Create an instance of faker
fake = Faker()
# Create a function


def get_transaction():
    number_of_transactions = rd.randint(500000, 1000000)
    transactions_data = []

    for i in range(number_of_transactions):
        transaction = {
            'first_name': fake.first_name(),
            'last_name': fake.last_name(),
            'transaction_id': fake.uuid4(),
            'customer_id': fake.random_int(min=1000, max=9999),
            'product_id': fake.ean13(),
            'transaction_date': fake.date_time_between(
             start_date='-1y', end_date='now'),
            'payment_method': rd.choice([
                'Credit Card', 'Debit Card', 'Cash', 'Online Transfer']),
            'store_location': fake.city()
        }
        transactions_data.append(transaction)

    df = pd.DataFrame(transactions_data)
    df['customer_id'] = df['customer_id'].astype("int32")
    df['transaction_date'] = pd.to_datetime(df['transaction_date'])

    return df


# Upload to s3
def upload_to_s3():
    df = get_transaction()
    session = boto3.session.Session(
                aws_access_key_id=Variable.get("AWS_ACCESS_KEY_ID"),
                aws_secret_access_key=Variable.get("AWS_SECRET_ACCESS_KEY"),
                region_name=Variable.get("REGION_NAME")
            )

    date_str = datetime.today().strftime('%Y-%m-%d')
    s3_bucket = 'faker-project'
    s3_folder = 'new_transaction_folder'
    path = f"s3://{s3_bucket}/{s3_folder}/{date_str}_data_file.parquet"
    wr.s3.to_parquet(
        df=df,
        path=path,
        dataset=False,
        index=False,
        boto3_session=session
    )
