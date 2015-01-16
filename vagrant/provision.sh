#!/usr/bin/env bash

# Define variables
HOST=mysite
FQDN=mysite.dev
MYSQL_ROOT_PASS=mysite
DB_NAME=mysite
DB_USER=root

# Use colored prompt for all users
echo -e "\nforce_color_prompt=yes" >> /etc/bash.bashrc

# Change to "/vagrant" directory after login
echo -e "\ncd /vagrant" >> /home/vagrant/.bashrc

# Change hostname
sed -i "s/127.0.1.1.*/127.0.1.1\t$FQDN\t$HOST/g" /etc/hosts
echo $FQDN > /etc/hostname
service hostname restart

# Update
apt-get update

# Set timezone and install NTP
echo "America/New_York" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
apt-get install -y ntp

# Install git
apt-get install -y git-core

# Preconfigure MySQL root password before installation
debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASS"

# Install PHP5, MySQL, Nginx and Memcached
apt-get install -y php5-fpm php5-cli php5-mysql mysql-server nginx

# Set cgi.fix_pathinfo to 0
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini

# Restart PHP-FPM
service php5-fpm restart

# Install composer globally
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Keep backup copy for existing config files (nginx.conf and mime.types)
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
mv /etc/nginx/mime.types /etc/nginx/mime.types.bak

# Remove "sites-available" and "sites-enabled" directories
rm -rf /etc/nginx/sites-available /etc/nginx/sites-enabled

# Use H5BP nginx server config
cd /tmp && git clone https://github.com/h5bp/server-configs-nginx.git nginx && cd nginx
mv nginx.conf /etc/nginx
mv mime.types /etc/nginx
mv h5bp /etc/nginx
mv sites-available /etc/nginx
mv sites-enabled /etc/nginx
cd .. && rm -rf nginx

# Fix few config in H5BP
sed -i "s/user www www;/user www-data www-data;/g" /etc/nginx/nginx.conf
sed -i "s/error_log\s\+logs\\/error.log/error_log  \\/var\\/log\\/nginx\\/error.log/g" /etc/nginx/nginx.conf
sed -i "s/access_log\s\+logs\\/access.log/access_log \\/var\\/log\\/nginx\\/access.log/g" /etc/nginx/nginx.conf
sed -i "s/sendfile\s\+on;/sendfile        off;\n\n  types_hash_max_size 2048;\n  server_names_hash_bucket_size 64;/g" /etc/nginx/nginx.conf
sed -i "s/access_log\s\+logs\\/static.log/access_log \\/var\\/log\\/nginx\\/static.log/g" /etc/nginx/h5bp/location/expires.conf
touch /var/log/nginx/static.log

# Create logs directory
su - vagrant -c "mkdir -p /vagrant/logs && touch /vagrant/logs/error.log && touch /vagrant/logs/access.log"

# Configure default site using server.conf
rm /etc/nginx/sites-available/*
ln -s /vagrant/vagrant/server.conf /etc/nginx/sites-available/default
ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Disable autostart from default init.d
update-rc.d -f nginx disable

# Create upstart job for nginx
cp /vagrant/vagrant/upstart.conf /etc/init/nginx.conf

# Create database
mysql -u $DB_USER -p$MYSQL_ROOT_PASS -e "CREATE DATABASE $DB_NAME"
