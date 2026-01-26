#!/bin/bash -xe

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Update package repo, add NodeJS source
apt-get -y update
apt-get -y upgrade
apt-get -y purge unattended-upgrades
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
apt-get -y install curl dirmngr apt-transport-https lsb-release ca-certificates python3-setuptools awscli nodejs gcc g++ make nginx

# Create users and groups
addgroup --system --gid 1033 juicer
adduser juicer --system --uid 1033 --ingroup juicer

# Install CloudFormation helper scripts
mkdir -p /opt/aws/bin
cd /
wget https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-py3-latest.tar.gz
python3 -m easy_install --script-dir /opt/aws/bin aws-cfn-bootstrap-py3-latest.tar.gz

# Store secret information in S3
echo "Dang it - if you can see this text, you're accessing our private information!" >/tmp/secret-information.txt
aws s3 cp /tmp/secret-information.txt s3://${secure_bucket}

# Configure Nginx to proxy to Node.js
cat > /etc/nginx/sites-available/default <<'EOF'
server {
  listen       80;
  server_name  localhost;
  location / {
    proxy_pass http://localhost:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
  }
}
EOF

# Configure Juice Shop systemd service
cat > /etc/systemd/system/juiceshop-service.service <<'EOF'
[Unit]
Description=Juice Shop Node JS Server Service
[Service]
User=juicer
WorkingDirectory=/juice-shop
ExecStart=/usr/bin/npm start
Restart=always
[Install]
WantedBy=multi-user.target
EOF

# Download juice-shop, set permissions, and build
wget -q https://github.com/juice-shop/juice-shop/releases/download/v13.3.0/juice-shop-13.3.0_node16_linux_x64.tgz
tar -xzf juice-shop-13.3.0_node16_linux_x64.tgz
mv juice-shop_13.3.0 juice-shop
cd /juice-shop
chown -R juicer .
mkdir logs
chown -R juicer logs
chgrp -R 0 ftp/ frontend/dist/ logs/ data/ i18n/
chmod -R g=u ftp/ frontend/dist/ logs/ data/ i18n/

# Start services
systemctl daemon-reload
systemctl enable juiceshop-service
systemctl start juiceshop-service
systemctl restart nginx
