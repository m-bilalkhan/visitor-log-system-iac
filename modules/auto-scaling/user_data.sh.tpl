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

SECRET_VALUE=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region "$REGION" \
  --query SecretString \
  --output text 2>/dev/null)

# Validate fetch
if [ -z "$SECRET_VALUE" ] || [ "$SECRET_VALUE" == "null" ]; then
  echo "❌ Failed to retrieve secret: $SECRET_NAME" >&2
  exit 1
fi

# Parse JSON or plain string
if command -v jq >/dev/null && echo "$SECRET_VALUE" | jq . >/dev/null 2>&1; then
  PASSWORD=$(echo "$SECRET_VALUE" | jq -r .password)
else
  PASSWORD="$SECRET_VALUE"
fi

chown ec2-user:ec2-user $ENV_FILE
