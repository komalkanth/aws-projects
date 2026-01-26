"""
Lambda function for automated GuardDuty remediation.
Revokes IAM sessions issued before a GuardDuty finding timestamp.
"""
import json
import boto3
import logging

iam_client = boto3.client("iam")
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """
    Handler function triggered by EventBridge on GuardDuty findings.

    Expected input format:
    {
        "RoleName": "string",
        "PolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [...]
        }
    }
    """
    try:
        # Extract parameters from the event
        role_name = event.get("RoleName")
        policy_document = event.get("PolicyDocument")

        if not role_name or not policy_document:
            logger.error("Missing required parameters: RoleName or PolicyDocument")
            return {
                "statusCode": 400,
                "body": json.dumps("Error: Missing required parameters")
            }

        logger.info(f"Revoking sessions for role: {role_name}")

        # Put the deny policy on the role to revoke old sessions
        response = iam_client.put_role_policy(
            RoleName=role_name,
            PolicyName="RevokeOldSessions",
            PolicyDocument=json.dumps(policy_document)
        )

        logger.info(f"Successfully attached RevokeOldSessions policy to role {role_name}")

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": f"Successfully revoked sessions for role: {role_name}",
                "role_name": role_name
            })
        }

    except iam_client.exceptions.NoSuchEntityException:
        logger.error(f"Role not found: {role_name}")
        return {
            "statusCode": 404,
            "body": json.dumps(f"Error: Role {role_name} not found")
        }

    except iam_client.exceptions.LimitExceededException:
        logger.error(f"Too many policies attached to role {role_name}")
        return {
            "statusCode": 400,
            "body": json.dumps(f"Error: Too many policies on role {role_name}")
        }

    except Exception as e:
        logger.error(f"Error applying policy: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(f"Error: {str(e)}")
        }
