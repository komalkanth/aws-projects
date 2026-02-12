## Creating VPC and Subnets using AWS CLI
In this step, we will create a VPC and subnets using AWS CLI using the `wpprofile` profile. We will capture the IDs of the created resources in variables for later use so that the same commands can be used in automation scripts.

### Step 1: Create a VPC
To create a VPC, we will use the `aws ec2 create-vpc` command. This command requires us to specify the CIDR block for our VPC, which defines the IP address range for our network.
```bash
aws ec2 create-vpc \
    --cidr-block 10.10.0.0/16 \
    --tag-specifications ResourceType=vpc,Tags='[{Key=Name,Value=wp-vpc}]' \
    --profile wpprofile
```

Fetch the VPC details using `aws ec2 describe-vpcs` and use filters to just filter the VPC ID and save it to a variable `wp_vpc_id` for later use:
```bash
wp_vpc_id=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=wp-vpc" \
    --query "Vpcs[0].VpcId" \
    --output text \
    --profile wpprofile)

~ $ echo "VPC ID: $wp_vpc_id"
VPC ID: vpc-0ebdc823c6c938ce2
```

### Step 2: Create Subnets
Next, we will create the below subnets in our VPC:
- Public Subnets: 2 subnets in different availability zones for high availability
- Private Subnets: 2 subnets in different availability zones for high availability and for subnet-groups for RDS

```bash
# Create Public Subnet 1
aws ec2 create-subnet \
    --vpc-id $wp_vpc_id \
    --cidr-block  10.10.0.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications ResourceType=subnet,Tags='[{Key=Name,Value=wp-public-subnet-1a}]' \
    --profile wpprofile

# Create Public Subnet 2
aws ec2 create-subnet \
    --vpc-id $wp_vpc_id \
    --cidr-block 10.10.1.0/24 \
    --availability-zone us-east-1b \
    --tag-specifications ResourceType=subnet,Tags='[{Key=Name,Value=wp-public-subnet-1b}]' \
    --profile wpprofile

# Create Private Subnet 1
aws ec2 create-subnet \
    --vpc-id $wp_vpc_id \
    --cidr-block 10.10.2.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications ResourceType=subnet,Tags='[{Key=Name,Value=wp-private-subnet-1a}]' \
    --profile wpprofile

# Create Private Subnet 2
aws ec2 create-subnet \
    --vpc-id $wp_vpc_id \
    --cidr-block 10.10.3.0/24 \
    --availability-zone us-east-1b \
    --tag-specifications ResourceType=subnet,Tags='[{Key=Name,Value=wp-private-subnet-1b}]' \
    --profile wpprofile
```
Fetch the Subnet details using `aws ec2 describe-subnets` and use filters to just filter the Subnet IDs and save them to variables for later use:
```bash
wp_public_subnet_1a_id=$(aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=wp-public-subnet-1a" \
    --query "Subnets[0].SubnetId" \
    --output text \
    --profile wpprofile)

wp_public_subnet_1b_id=$(aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=wp-public-subnet-1b" \
    --query "Subnets[0].SubnetId" \
    --output text \
    --profile wpprofile)

wp_private_subnet_1a_id=$(aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=wp-private-subnet-1a" \
    --query "Subnets[0].SubnetId" \
    --output text \
    --profile wpprofile)

wp_private_subnet_1b_id=$(aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=wp-private-subnet-1b" \
    --query "Subnets[0].SubnetId" \
    --output text \
    --profile wpprofile)
```
#### Output the Subnet IDs
```bash
~ $ echo "Public Subnet 1a ID: $wp_public_subnet_1a_id"
Public Subnet 1a ID: subnet-0a6d783e4476b540d

~ $ echo "Public Subnet 1b ID: $wp_public_subnet_1b_id"
Public Subnet 1b ID: subnet-09fd4504b186739fb

~ $ echo "Private Subnet 1a ID: $wp_private_subnet_1a_id"
Private Subnet 1a ID: subnet-092220c3a8d32db4e

~ $ echo "Private Subnet 1b ID: $wp_private_subnet_1b_id"
Private Subnet 1b ID: subnet-0e07ce7bfd91abcc4
```

### Step 3: Create an Internet Gateway and attach it to the VPC
To allow our resources in the public subnets to access the internet, we need to create an Internet Gateway and attach it to our VPC.
```bash
# Create Internet Gateway
aws ec2 create-internet-gateway \
    --tag-specifications ResourceType=internet-gateway,Tags='[{Key=Name,Value=wp-igw}]' \
    --profile wpprofile

# Fetch the Internet Gateway ID
wp_igw_id=$(aws ec2 describe-internet-gateways \
    --filters "Name=tag:Name,Values=wp-igw" \
    --query "InternetGateways[0].InternetGatewayId" \
    --output text \
    --profile wpprofile)

# Output the Internet Gateway ID
echo "Internet Gateway ID: $wp_igw_id"
Internet Gateway ID: igw-00d517e235779120f

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway \
    --vpc-id $wp_vpc_id \
    --internet-gateway-id $wp_igw_id \
    --profile wpprofile
```

### Step 4: Create a Route Table and associate it with the public subnets
To route traffic from our public subnets to the internet, we need to create a Route Table and associate it with our public subnets.
```bash
# Create Route Table
aws ec2 create-route-table \
    --vpc-id $wp_vpc_id \
    --tag-specifications ResourceType=route-table,Tags='[{Key=Name,Value=wp-public-rt}]' \
    --profile wpprofile

# Fetch the Route Table ID
wp_public_rt_id=$(aws ec2 describe-route-tables \
    --filters "Name=tag:Name,Values=wp-public-rt" \
    --query "RouteTables[0].RouteTableId" \
    --output text \
    --profile wpprofile)

# Output the Route Table ID
~ $ echo "Public Route Table ID: $wp_public_rt_id"
Public Route Table ID: rtb-023431a6db7034951

# Create a default route to the Internet Gateway
aws ec2 create-route \
    --route-table-id $wp_public_rt_id \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $wp_igw_id \
    --profile wpprofile

# Associate the Route Table with the public subnet 1a
aws ec2 associate-route-table \
    --route-table-id $wp_public_rt_id \
    --subnet-id $wp_public_subnet_1a_id \
    --profile wpprofile

# Associate the Route Table with the public subnet 1b
aws ec2 associate-route-table \
    --route-table-id $wp_public_rt_id \
    --subnet-id $wp_public_subnet_1b_id \
    --profile wpprofile
```

### Step 5: Create Security Groups for ECS tasks and Front end Load Balancer
To control access to our resources, we need to create Security Groups. We will create two security groups:
- **ECS Security Group**: This security group will allow traffic from the Load Balancer to the ECS tasks on port 80 and allow outbound traffic to the RDS instance on port 3306.
- **Load Balancer Security Group**: This security group will allow inbound traffic  from the internet on port 80 and allow outbound traffic to the ECS tasks on port 80.

```bash

# Create Load Balancer Security Group
aws ec2 create-security-group \
    --group-name wp-lb-sg \
    --description "Security group for Load Balancer" \
    --vpc-id $wp_vpc_id \
    --profile wpprofile

# Fetch the Load Balancer Security Group ID
wp_lb_sg_id=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=wp-lb-sg" \
    --query "SecurityGroups[0].GroupId" \
    --output text \
    --profile wpprofile)

# Output the Load Balancer Security Group ID
~ $ echo "Load Balancer Security Group ID: $wp_lb_sg_id"
Load Balancer Security Group ID: sg-08afb0e8d7f88cb94

# Authorize inbound traffic on port 80 from the internet to Load Balancer Security Group
aws ec2 authorize-security-group-ingress \
    --group-id $wp_lb_sg_id \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --profile wpprofile

# Create ECS Security Group
aws ec2 create-security-group \
    --group-name wp-ecs-sg \
    --description "Security group for ECS tasks" \
    --vpc-id $wp_vpc_id \
    --profile wpprofile

# Fetch the ECS Security Group ID
wp_ecs_sg_id=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=wp-ecs-sg" \
    --query "SecurityGroups[0].GroupId" \
    --output text \
    --profile wpprofile)

# Output the ECS Security Group ID
~ $ echo "ECS Security Group ID: $wp_ecs_sg_id"
ECS Security Group ID: sg-06368c36fcfa4da9c

# Authorize inbound traffic on port 80 from the Load Balancer Security Group
aws ec2 authorize-security-group-ingress \
    --group-id $wp_ecs_sg_id \
    --protocol tcp \
    --port 80 \
    --source-group $wp_lb_sg_id \
    --profile wpprofile


```
