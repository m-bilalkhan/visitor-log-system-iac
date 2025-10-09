import os
import psycopg2
import boto3
import json

def handler(event, context):
    secret_name = os.environ["DB_SECRET_ARN"]
    host = os.environ["DB_HOST"]
    port = os.environ["DB_PORT"]
    dbname = os.environ["DB_NAME"]
    sm = boto3.client("secretsmanager")
    secret = json.loads(sm.get_secret_value(SecretId=secret_name)["SecretString"])

    conn = psycopg2.connect(
        host=secret["host"],
        user=secret["username"],
        password=secret["password"],
        dbname=secret["dbname"]
    )
    cur = conn.cursor()
    cur.execute(f"CREATE ROLE {event['iam_role_name']} LOGIN;")
    cur.execute(f"GRANT rds_iam TO {event['iam_role_name']};")
    conn.commit()
    cur.close()
    conn.close()
    return {"status": "ok"}
