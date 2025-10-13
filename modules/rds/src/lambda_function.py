import os
import psycopg2
import boto3
import json
import traceback

def handler(event, context):
    print("=== Lambda Execution Started ===")

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

        iam_role_name = os.environ["DB_ROLE_NAME"]
        if not iam_role_name:
            raise ValueError("Missing 'iam_role_name' in event")

        # --- Step 1: Create role if not exists ---
        print(f"🔍 Checking or creating PostgreSQL role: {iam_role_name}")
        cur.execute("""
            DO $$
            BEGIN
                IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = %s) THEN
                    EXECUTE format('CREATE ROLE %I LOGIN;', %s);
                    EXECUTE format('GRANT rds_iam TO %I;', %s);
                ELSE
                    RAISE NOTICE 'Role % already exists, skipping creation.', %s;
                END IF;
            END
            $$;
        """, (iam_role_name, iam_role_name, iam_role_name, iam_role_name))
        print(f"✅ Role ensured: {iam_role_name}")

        # --- Step 2: Create visitors table if not exists ---
        print("🔍 Ensuring visitors table exists...")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS visitors (
                id SERIAL PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(150) NOT NULL,
                location VARCHAR(255),
                message TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        print("✅ visitors table ensured")


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
