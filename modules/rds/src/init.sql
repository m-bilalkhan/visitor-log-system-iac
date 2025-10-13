DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '{{ROLE_NAME}}') THEN
        EXECUTE format('CREATE ROLE %I LOGIN', '{{ROLE_NAME}}');
        EXECUTE format('GRANT rds_iam TO %I', '{{ROLE_NAME}}');
    ELSE
        RAISE NOTICE 'Role {{ROLE_NAME}} already exists, skipping creation.';
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS visitors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    location VARCHAR(100),
    message TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
