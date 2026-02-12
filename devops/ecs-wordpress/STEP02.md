# Creating RDS Database and related components

In this step, we will create an RDS database instance to host our database for the Wordpress website. We will also use Secrets Manager secret to securely store the database credentials which is an option when creating the RDS instance.

## Step 1: Create a subnet group for RDS
Before we create the RDS instance, we need to create a subnet group that includes the private subnets we created in the previous step. This will allow our RDS instance to be launched in the private subnets for better security.

```bash
# Create RDS subnet group
aws rds create-db-subnet-group \
    --db-subnet-group-name wp-db-subnet-group \
    --db-subnet-group-description "Subnet group for Wordpress RDS instance" \
    --subnet-ids $wp_private_subnet_1a_id $wp_private_subnet_1b_id \
    --profile wpprofile

    # Fetch the RDS subnet group name
wp_db_subnet_group_name=$(aws rds describe-db-subnet-groups \
    --filters "Name=db-subnet-group-name,Values=wp-db-subnet-group" \
    --query "DBSubnetGroups[0].DBSubnetGroupName" \
    --output text \
    --profile wpprofile)

# Output the RDS subnet group name
~ $ echo "RDS Subnet Group Name: $wp_db_subnet_group_name"
RDS Subnet Group Name: wp-db-subnet-group
```

## Step 2: Create a security group for RDS
Next, we need to create a security group for our RDS instance. This security group will allow inbound traffic on the MySQL port (3306) from the whole VPC CIDR block, which will allow our ECS tasks to connect to the RDS instance.

```bash
# Create RDS security group
aws ec2 create-security-group \
    --group-name wp-db-sg \
    --description "Security group for Wordpress RDS instance" \
    --vpc-id $wp_vpc_id \
    --profile wpprofile

# Fetch the RDS Security Group ID
wp_db_sg_id=$(aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=wp-db-sg" \
    --query "SecurityGroups[0].GroupId" \
    --output text \
    --profile wpprofile)

# Output the RDS Security Group ID
~ $ echo "RDS Security Group ID: $wp_db_sg_id"
RDS Security Group ID: sg-01b9babab7b84de4d

# Authorize inbound traffic on port 3306 from the VPC CIDR block
aws ec2 authorize-security-group-ingress \
    --group-id $wp_db_sg_id \
    --protocol tcp \
    --port 3306 \
    --cidr 10.10.0.0/16 \
    --profile wpprofile
```


## Step 3: Create RDS database instance
Now that we have the subnet group ready, we can create the RDS database instance. We will specify the database engine as MySQL, allocate storage, and associate it with the security group we created.
We will let the AWS Secrets Manager handle the master user password by using the `--manage-master-user-password` option, which will create a secret in Secrets Manager to store the credentials securely.


```bash
# Create RDS database instance
aws rds create-db-instance \
    --db-instance-identifier wordpress \
    --db-instance-class db.t4g.micro \
    --engine mysql \
    --allocated-storage 20 \
    --storage-type gp3 \
    --master-username admin \
    --manage-master-user-password \
    --vpc-security-group-ids $wp_db_sg_id \
    --db-subnet-group-name $wp_db_subnet_group_name \
    --no-publicly-accessible \
    --profile wpprofile

# RDS instance creation can take a while. Run the below command. Once the command returns without any error, it means the RDS instance is available and we can proceed to the next steps.

aws rds wait db-instance-available \
    --db-instance-identifier wordpress \
    --profile wpprofile

# Fetch the RDS endpoint address
wp_db_endpoint=$(aws rds describe-db-instances \
    --db-instance-identifier wordpress \
    --query "DBInstances[0].Endpoint.Address" \
    --output text \
    --profile wpprofile)

# Output the RDS endpoint address
~ $ echo "RDS Endpoint Address: $wp_db_endpoint"
RDS Endpoint Address: wordpress.ckn8g0ce0h5y.us-east-1.rds.amazonaws.com
```

## Step 4: Create an initial database named wordpress
After the RDS instance is available, we need to create an initial database named `wordpress` which our Wordpress application will use to store its data. We can do this by connecting to the RDS instance using the master username and password stored in Secrets Manager.

*Note that the RDS instance is launched in a private subnet, so we cannot connect to it directly from our local machine. We will need to use an EC2 instance in the same VPC to connect to the RDS instance and run the MySQL command to create the database.*

```bash
# Fetch the master username and password from Secrets Manager
wp_db_secret_arn=$(aws rds describe-db-instances \
    --db-instance-identifier wordpress \
    --query "DBInstances[0].MasterUserSecret.SecretArn" \
    --output text \
    --profile wpprofile)

wp_db_secret_value=$(aws secretsmanager get-secret-value \
    --secret-id $wp_db_secret_arn \
    --query "SecretString" \
    --output text \
    --profile wpprofile)

# Extract the username and password from the secret value
wp_db_username=$(echo $wp_db_secret_value | jq -r '.username')
wp_db_password=$(echo $wp_db_secret_value | jq -r '.password')
```

## Step 5: Connect to the RDS instance and create the wordpress database

```bash
ubuntu@ip-10-10-0-14:~$ mysql -h $wp_db_endpoint -u $wp_db_username -p
Enter password:
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MySQL connection id is 33
Server version: 8.4.7 Source distribution

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MySQL [(none)]> CREATE DATABASE wordpress;
Query OK, 1 row affected (0.055 sec)

MySQL [(none)]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| wordpress          |
+--------------------+
5 rows in set (0.014 sec)

```

## Step 6: Store RDS connection details in SSM Parameter Store
Finally, we will store the RDS connection details (endpoint and Database name) in SSM Parameter Store so that our Wordpress container can access these details to connect to the database.

```bash
# Store RDS endpoint in SSM Parameter Store
aws ssm put-parameter \
    --name /dev/WORDPRESS_DB_HOST \
    --value $wp_db_endpoint:3306 \
    --type String \
    --profile wpprofile

# Store RDS database name in SSM Parameter Store
aws ssm put-parameter \
    --name /dev/WORDPRESS_DB_NAME \
    --value wordpress \
    --type String \
    --profile wpprofile
```

