#!/bin/bash
set -e

REGION="${region}"
ENV_PATH="/${project_name}/${env}"

ENV_FILE="/home/ec2-user/app/.env"

# -------------------------------------
# 1. Fetch parameters from SSM
# -------------------------------------
PARAMS=$(aws ssm get-parameters-by-path \
  --path "$ENV_PATH" \
  --with-decryption \
  --region "$REGION" \
  --query "Parameters[*].{Name:Name,Value:Value}" \
  --output text)


# Write all SSM params to .env
echo "$PARAMS" | while read Name Value; do
  Key=$(basename "$Name")
  echo "$${Key^^}=$Value" >> "$ENV_FILE"
done

# -------------------------------------
# 2. Generate RDS IAM Auth Token
# -------------------------------------
DB_HOST=$(grep '^DB_HOST=' "$ENV_FILE" | cut -d'=' -f2)
DB_PORT=$(grep '^DB_PORT=' "$ENV_FILE" | cut -d'=' -f2)
DB_USER=$(grep '^DB_USER=' "$ENV_FILE" | cut -d'=' -f2)

if [ -n "$DB_HOST" ] && [ -n "$DB_USER" ]; then
  echo "Generating RDS IAM auth token..."
  DB_PASSWORD=$(aws rds generate-db-auth-token \
    --hostname "$DB_HOST" \
    --port "$${DB_PORT:-5432}" \
    --region "$REGION" \
    --username "$DB_USER")
  
  echo "DB_PASSWORD=$DB_PASSWORD" >> "$ENV_FILE"
else
  echo "Skipping RDS token — missing DB_HOST or DB_USER"
fi

# -------------------------------------
# 3. Set ownership
# -------------------------------------
chown ec2-user:ec2-user "$ENV_FILE"
