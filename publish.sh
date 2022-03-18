#!/bin/bash

source ./config.sh

DESCRIPTION="GGP config layer for GoCheckIn"
FILENAME=${LAYER_NAME}-${SYSTEM_NAME}

aws s3api create-bucket --bucket ${BUCKET} --create-bucket-configuration LocationConstraint=ap-southeast-1

aws s3api put-object --bucket ${BUCKET} --key layers/${FILENAME} --body ./tmp/layer.zip

for REGION in $REGIONS; do
  aws s3api create-bucket --bucket ${BUCKET}-${REGION} --region $REGION --create-bucket-configuration LocationConstraint=$REGION
done

for REGION in $REGIONS; do
  aws s3api copy-object --region $REGION --copy-source ${BUCKET}/layers/${FILENAME} \
    --bucket ${BUCKET}-${REGION} --key layers/${FILENAME} && \
  aws lambda publish-layer-version --region $REGION --layer-name $FILENAME \
      --content S3Bucket=${BUCKET}-${REGION},S3Key=layers/${FILENAME} \
      --compatible-runtimes "java8" \
      --description "$DESCRIPTION" --query Version --output text
done

for job in $(jobs -p); do
  wait $job
done