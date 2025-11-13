import logging
import random as rd
from random import randint

import awswrangler as wr
import pandas as pd
from Airflow.aws_utils import new_session
from Airflow.date_utils import date_str
from faker import Faker

logging.basicConfig(format='%(asctime)s %(levelname)s:%(name)s:%(message)s')
logging.getLogger().setLevel(20)

fake = Faker()
logging.info("finished faker module instantiation")


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

    session = new_session
    new_date = date_str
    s3_bucket = 'sales-project'
    s3_folder = 'new_transaction_folder'
    path = f"s3://{s3_bucket}/{s3_folder}/{new_date}_data_file.parquet"
    wr.s3.to_parquet(
        df=df,
        path=path,
        dataset=False,
        index=False,
        boto3_session=session
        )

    return "Data written to S3 completed successfully"
