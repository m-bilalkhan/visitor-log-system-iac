import os
import psycopg2
import boto3
import json
import traceback

def handler(event, context):
    print("=== Lambda Execution Started ===")
    print(f"Event received: {json.dumps(event)}")

    try:
        # Environment variables
        secret_name = os.environ["DB_SECRET_ARN"]
        host = os.environ["DB_HOST"]
        port = os.environ["DB_PORT"]
        dbname = os.environ["DB_NAME"]
        username = os.environ["DB_USERNAME"]

        # Fetch DB credentials from Secrets Manager
        sm = boto3.client("secretsmanager")
        secret_value = sm.get_secret_value(SecretId=secret_name)
        secret = json.loads(secret_value["SecretString"])

        # Connect to PostgreSQL
        conn = psycopg2.connect(
            host=host,
            user=username,
            password=secret["password"],
            dbname=dbname,
            port=port,
            connect_timeout=60
        )
        print("Database connection established")

        # Create cursor
        cur = conn.cursor()

        iam_role_name = event.get("iam_role_name")
        if not iam_role_name:
            raise ValueError("Missing 'iam_role_name' in event")

        print(f"Creating PostgreSQL role: {iam_role_name}")

        # Execute SQL commands
        cur.execute(f"CREATE ROLE {iam_role_name} LOGIN;")
        cur.execute(f"GRANT rds_iam TO {iam_role_name};")

        conn.commit()
        print(f"Successfully created role and granted rds_iam to {iam_role_name}")

        # Cleanup
        cur.close()
        conn.close()

        print("Database connection closed")
        print("=== Lambda Execution Completed Successfully ===")

        return {"status": "ok", "role": iam_role_name}

    except Exception as e:
        print("!!! ERROR OCCURRED DURING EXECUTION !!!")
        print(f"Error Type: {type(e).__name__}")
        print(f"Error Message: {str(e)}")
        print("Stack Trace:")
        traceback.print_exc()
        print("=== Lambda Execution Failed ===")

        return {
            "status": "error",
            "error_type": type(e).__name__,
            "message": str(e),
            "trace": traceback.format_exc(),
        }
