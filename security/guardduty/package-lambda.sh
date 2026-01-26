#!/bin/bash

# Script to package the Lambda function into a zip file
# Run this before running terraform apply

set -e

echo "Packaging Lambda function..."

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Copy the Lambda function to the temp directory
cp remediation_lambda.py "$TEMP_DIR/index.py"

# Create the zip file
cd "$TEMP_DIR"
zip -q remediation_lambda.zip index.py

# Move the zip file back to the Terraform directory
mv remediation_lambda.zip "$OLDPWD/"

echo "✓ Lambda function packaged: remediation_lambda.zip"
echo "You can now run: terraform apply"
