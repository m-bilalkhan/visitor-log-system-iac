#!/bin/bash
set -e

REGION="${region}"
ENV_PATH="/${project_name}/${env}"

PARAMS=$(aws ssm get-parameters-by-path \
  --path "$ENV_PATH" \
  --with-decryption \
  --region $REGION \
  --query "Parameters[*].{Name:Name,Value:Value}" \
  --output text)

ENV_FILE="/home/ec2-user/app/.env"

echo "$PARAMS" | while read Name Value; do
  Key=$(basename "$Name")
  echo "$${Key^^}=$Value" >> $ENV_FILE
done

# 2. Fetch rotating DB password from Secrets Manager
SECRET_NAME="${project_name}-${env}-db-master-password"

DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region $REGION \
  --query 'SecretString' \
  --output text)

# If password is JSON (depends on RDS), parse it
if echo "$DB_PASSWORD" | jq . >/dev/null 2>&1; then
  PASSWORD=$(echo "$DB_PASSWORD" | jq -r .password)
  echo "DB_PASSWORD=$PASSWORD" >> $ENV_FILE
else
  # plain text secret
  echo "DB_PASSWORD=$DB_PASSWORD" >> $ENV_FILE
fi

chown ec2-user:ec2-user $ENV_FILE
