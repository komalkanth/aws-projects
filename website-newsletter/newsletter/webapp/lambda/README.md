# Newsletter Subscribe Lambda

Minimal backend handler for processing newsletter subscriptions.

## Environment Variables

These variables must be configured in the Lambda function console:

| Variable | Description | Example |
| :--- | :--- | :--- |
| `DYNAMODB_TABLE_NAME` | Name of the DynamoDB table to store emails | `newsletter-subscribers` |
| `SES_SOURCE_EMAIL` | Verified SES email address used as sender | `info@kkoncloud.net` |
| `SES_DESTINATION_EMAIL`| Email address to receive notification of new signups | `admin@kkoncloud.net` |
| `ALLOWED_ORIGIN` | Allowed origin for CORS (no trailing slash) | `https://awsconsult.kkoncloud.net` |
| `ENVIRONMENT` | Deployment environment label | `prod` or `dev` |

## Prerequisites

1.  **DynamoDB Table**: A table with a Partition Key (String) named `email`.
2.  **SES Identity**: Both `SES_SOURCE_EMAIL` and `SES_DESTINATION_EMAIL` must be verified in the SES console (or you must be out of the SES Sandbox).
3.  **IAM Permissions**:
    *   `dynamodb:PutItem` on the specified table.
    *   `ses:SendEmail` for the source identity.
    *   `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` for CloudWatch.
