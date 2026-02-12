# Containerizing Wordpress with Amazon ECS and Fargate
This project demonstrates how to host a Wordpress website on AWS ECS using Fargate and RDS for the database. Just to make this little bit fun, I'm going to create a monimally modified Wordpress Docket image, upload it to ECR and use that image in our ECS task definition. The main goal is to understand how to deploy a Wordpress website on AWS ECS and manage it effectively.

## Step 1: Create a local minimally modified Wordpress Docker image
To create a local Docker image for our Wordpress website, we will start with the official Wordpress image from Docker Hub and make a small modification to it. We will create a custom Dockerfile that extends the official Wordpress image and adds a simple HTML file to the container.
### Create a Dockerfile
Create a file named `Dockerfile` in your local directory with the following content:
```Dockerfile
# Use the official Wordpress image as the base image
FROM wordpress:latest

# Add a simple HTML file to the container
RUN echo "<h1>Welcome to My Wordpress Website!</h1>" > /var/www/html/index.html
```

### Build the Docker image
Next, we will build the Docker image using the `docker build` command. We will tag the image with a name that we can use later when pushing it to ECR.

```bash
docker build -t my-wordpress-image .
[+] Building 0.5s (6/6) FINISHED                                                        docker:default
 => [internal] load build definition from Dockerfile                                              0.0s
 => => transferring dockerfile: 235B                                                              0.0s
 => [internal] load metadata for docker.io/library/wordpress:latest                               0.0s
 => [internal] load .dockerignore                                                                 0.0s
 => => transferring context: 2B                                                                   0.0s
 => [1/2] FROM docker.io/library/wordpress:latest                                                 0.1s
 => [2/2] RUN echo "<h1>Welcome to My Wordpress Website!</h1>" > /var/www/html/index.html         0.3s
 => exporting to image                                                                            0.0s
 => => exporting layers                                                                           0.0s
 => => writing image sha256:da7b6e5b099c5cd6b725941ba64f0023da422acb4e564234a9906a0c316ae0f2      0.0s
 => => naming to docker.io/library/my-wordpress-image

 ❯ docker image ls | grep my-wordpress
my-wordpress-image       latest    da7b6e5b099c   46 seconds ago   734MB
```

## Step 2: Push the Docker image to Amazon ECR
Now that we have our Docker image built locally, we need to push it to Amazon ECR (Elastic Container Registry) so that it can be used in our ECS task definition. We will create an ECR repository, authenticate Docker to the registry, and then push our image.

### Create an ECR repository
To create an ECR repository, we will use the `aws ecr create-repository` command. This command requires us to specify the name of the repository we want to create.

```bash
aws ecr create-repository \
    --repository-name my-wordpress-repo \
    --profile wpprofile

# Fetch the ECR repository URI
wp_ecr_repo_uri=$(aws ecr describe-repositories \
    --repository-names my-wordpress-repo \
    --query "repositories[0].repositoryUri" \
    --output text \
    --profile wpprofile)

# Output the ECR repository URI
~ $ echo "ECR Repository URI: $wp_ecr_repo_uri"
ECR Repository URI: 937115287938.dkr.ecr.us-east-1.amazonaws.com/my-wordpress-repo
```

### Authenticate Docker to the ECR registry
Before we can push our Docker image to ECR, we need to authenticate Docker to the registry. We can do this using the `aws ecr get-login-password` command, which retrieves an authentication token that we can use to authenticate Docker.

```bash
aws ecr get-login-password \
    --region us-east-1 \
    --profile wpprofile | docker login \
    --username AWS \
    --password-stdin $wp_ecr_repo_uri
```

### Tag and push the Docker image to ECR
Now that we are authenticated, we need to tag our local Docker image with the ECR repository URI and then push it to ECR.

```bash
# Tag the local Docker image with the ECR repository URI
docker tag my-wordpress-image:latest $wp_ecr_repo_uri:latest

# Push the Docker image to ECR
docker push $wp_ecr_repo_uri:latest
The push refers to repository [937115287938.dkr.ecr.us-east-1.amazonaws.com/my-wordpress-repo]
066d4b04624a: Pushed
59ec196e1f23: Pushed
a7bda80a7d10: Pushed
70a290c5e58b: Pushed
.....
latest: digest: sha256:14103d0b40564591e2df4726c41125e18d54a263a197eb1571fef09accf29230 size: 5537
```

## Step 3: Create an ECS Cluster and Fargate Task Definition

Now that we have our Docker image pushed to ECR, we can create an ECS Cluster and a Fargate Task Definition to run our Wordpress container.

### Create an ECS Task Execution Role and Task Role
Before we create the ECS Task Definition, we need to create two IAM roles: one for task execution and one for the task itself. The task execution role allows ECS to pull the Docker image from ECR and manage the task, while the task role allows the container to access AWS resources (like Secrets Manager for database credentials).

```bash
# Create Task Execution Role
aws iam create-role \
    --role-name OurEcsTaskExecutionRole \
    --assume-role-policy-document file://task-execution-assume-role-policy.json \
    --profile wpprofile

# Attach the AWS managed policy for ECS Task Execution
aws iam attach-role-policy \
    --role-name OurEcsTaskExecutionRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy \
    --profile wpprofile

# Attach custom policy for Secrets Manager access
aws iam put-role-policy \
    --role-name OurEcsTaskExecutionRole \
    --policy-name SecretsManagerAccess \
    --policy-document file://secrets-manager-policy.json \
    --profile wpprofile

# Fetch the Task Execution Role ARN
wp_task_execution_role_arn=$(aws iam get-role \
    --role-name OurEcsTaskExecutionRole \
    --query "Role.Arn" \
    --output text \
    --profile wpprofile)


# Create Task Role
aws iam create-role \
    --role-name OurEcsTaskRole \
    --assume-role-policy-document file://task-assume-role-policy.json \
    --profile wpprofile

# Fetch the Task Role ARN
wp_task_role_arn=$(aws iam get-role \
    --role-name OurEcsTaskRole \
    --query "Role.Arn" \
    --output text \
    --profile wpprofile)
```

### Create an ECS Task Definition
To create an ECS Task Definition, we will use the AWS CLI based on the steps below.

```bash
aws ecs register-task-definition \
    --family wordpress-td \
    --network-mode awsvpc \
    --requires-compatibilities FARGATE \
    --cpu "256" \
    --memory "512" \
    --execution-role-arn "$wp_task_execution_role_arn" \
    --task-role-arn "$wp_task_role_arn" \
    --container-definitions '[
        {
            "name": "wordpress-container",
            "image": "'"$wp_ecr_repo_uri"':latest",
            "portMappings": [
                {
                    "containerPort": 80,
                    "protocol": "tcp"
                }
            ],
            "environment": [
                {
                    "name": "WORDPRESS_DB_HOST",
                    "value": "'"$wp_db_endpoint"'"
                },
                {
                    "name": "WORDPRESS_DB_USER",
                    "value": "admin"
                },
                {
                    "name": "WORDPRESS_DB_NAME",
                    "value": "wordpress"
                }
            ],
            "secrets": [
                {
                    "name": "WORDPRESS_DB_PASSWORD",
                    "valueFrom": "'"$wp_db_secret_arn"':password::"
                }
            ]
        }
    ]' \
    --profile wpprofile

# Fetch the Task Definition ARN
wp_task_definition_arn=$(aws ecs describe-task-definition \
    --task-definition wordpress-td \
    --query "taskDefinition.taskDefinitionArn" \
    --output text \
    --profile wpprofile)

# Output the Task Definition ARN
$ echo "Task Definition ARN: $wp_task_definition_arn"
Task Definition ARN: arn:aws:ecs:us-east-1:937115287938:task-definition/wordpress-td:1
```

## Step 4: Create an ECS Cluster
Next, we will create an ECS Cluster using the `aws ecs create-cluster` command. For the infrastructure we will use FARGATE_SPOT for easy management and low cost.

```bash
aws ecs create-cluster \
    --cluster-name wordpress-cluster \
    --capacity-providers FARGATE \
    --profile wpprofile

# Fetch the ECS Cluster ARN
wp_ecs_cluster_arn=$(aws ecs describe-clusters \
    --clusters wordpress-cluster \
    --query "clusters[0].clusterArn" \
    --output text \
    --profile wpprofile)

# Output the ECS Cluster ARN
~ $ echo "ECS Cluster ARN: $wp_ecs_cluster_arn"
ECS Cluster ARN: arn:aws:ecs:us-east-1:937115287938:cluster/wordpress-cluster
```

## Step 5: Create a Load Balancer and Target Group
To distribute traffic to our Wordpress container, we will create an Application Load Balancer named `OurApplicationLoadBalancer` and a Target group named `wordpress-tg` using the AWS CLI.

```bash
# Create an Application Load Balancer
aws elbv2 create-load-balancer \
    --name OurApplicationLoadBalancer \
    --subnets $wp_public_subnet_1a_id $wp_public_subnet_1b_id \
    --security-groups $wp_lb_sg_id \
    --profile wpprofile

# Fetch the Load Balancer ARN
wp_lb_arn=$(aws elbv2 describe-load-balancers \
    --names OurApplicationLoadBalancer \
    --query "LoadBalancers[0].LoadBalancerArn" \
    --output text \
    --profile wpprofile)

# Output the Load Balancer ARN
~ $ echo "Load Balancer ARN: $wp_lb_arn"
Load Balancer ARN: arn:aws:elasticloadbalancing:us-east-1:937115287938:loadbalancer/app/OurApplicationLoadBalancer/7a5fa1129399606a

# Create a Target Group. target-type is important to be "ip" for Fargate tasks
aws elbv2 create-target-group \
    --name wordpress-tg \
    --protocol HTTP \
    --port 80 \
    --vpc-id $wp_vpc_id \
    --target-type ip \
    --profile wpprofile

# Fetch the Target Group ARN
wp_tg_arn=$(aws elbv2 describe-target-groups \
    --names wordpress-tg \
    --query "TargetGroups[0].TargetGroupArn" \
    --output text \
    --profile wpprofile)

# Output the Target Group ARN
~ $ echo "Target Group ARN: $wp_tg_arn"

# Associate the Target Group with the Load Balancer
aws elbv2 create-listener \
    --load-balancer-arn $wp_lb_arn \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$wp_tg_arn \
    --profile wpprofile

```

## Step 6: Create a Fargate Service

Finally, we will create a Fargate Service to run our Wordpress container using the `aws ecs create-service` command.

```bash
aws ecs create-service \
    --cluster wordpress-cluster \
    --service-name wordpress-service \
    --task-definition $wp_task_definition_arn \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$wp_public_subnet_1a_id,$wp_public_subnet_1b_id],securityGroups=[$wp_ecs_sg_id],assignPublicIp=ENABLED}" \
    --load-balancers "targetGroupArn=$wp_tg_arn,containerName=wordpress-container,containerPort=80" \
    --health-check-grace-period-seconds 30 \
    --profile wpprofile
```


## Verification

Once the service is created, it will start running our Wordpress container. You can check the status of the service and the tasks using the AWS Management Console or the AWS CLI.

```bash
aws ecs describe-services \
    --cluster wordpress-cluster \
    --services wordpress-service \
    --query "services[0].{Status:status,DesiredCount:desiredCount,RunningCount:runningCount}" \
    --output table \
    --profile wpprofile
```

Since our service count is 1, we should see one task running. You can also check the logs of the container to ensure that Wordpress is running correctly.

Once the task comes up and is healthy, you can access the Wordpress website using the DNS name of the Load Balancer. You can find the DNS name in the AWS Management Console under the Load Balancer details or by using the AWS CLI.

```bash
aws elbv2 describe-load-balancers \
    --names OurApplicationLoadBalancer \
    --query "LoadBalancers[0].DNSName" \
    --output text \
    --profile wpprofile
```
