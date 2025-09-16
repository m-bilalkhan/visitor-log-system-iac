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

ENV_FILE="/home/ec2-user/.env"
rm -f $ENV_FILE

echo "$PARAMS" | while read Name Value; do
  Key=$(basename "$Name")
  echo "${Key^^}=$Value" >> $ENV_FILE
done

chown ec2-user:ec2-user $ENV_FILE
systemctl enable docker-compose-app.service
systemctl start docker-compose-app.service
