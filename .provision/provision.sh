#!/usr/bin/env bash

# Define variables
HOST="mysite"
MYSQL_ROOT_PASS="mysite"
DB_NAME="mysite"
DB_USER="root"

# Remember current directory
_PWD=`pwd`

# Use colored prompt for all users
echo -e "\nforce_color_prompt=yes" >> /etc/bash.bashrc

# Change hostname
echo $HOST > /etc/hostname
service hostname restart

# Update
apt-get update

# Set timezone and install NTP
echo "America/New_York" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
apt-get install -y ntp

# Install git
apt-get install -y git

# Install dotfiles
su - vagrant -c "git clone https://github.com/mislam/dotfiles.git /home/vagrant/.dotfiles && /home/vagrant/.dotfiles/scripts/install.sh"

# Change to "/vagrant" directory after login
echo -e "\ncd /vagrant" >> /home/vagrant/.bashrc

# Preconfigure MySQL root password before installation
debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASS"

# Install php5, mysql and nginx
apt-get install -y php5-fpm php5-cli php5-mysql mysql-server nginx

# Disable nginx autostart by init.d
update-rc.d -f nginx disable

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
cd /tmp && git clone https://github.com/h5bp/server-configs-nginx.git nginx-configs && cd nginx-configs
mv nginx.conf /etc/nginx
mv mime.types /etc/nginx
mv h5bp /etc/nginx
mv sites-available /etc/nginx
mv sites-enabled /etc/nginx
cd .. && rm -rf nginx-configs && cd $_PWD

# Fix few config in H5BP
sed -i "s/user www www;/user www-data www-data;/g" /etc/nginx/nginx.conf
sed -i "s/error_log\s\+logs\\/error.log/error_log  \\/var\\/log\\/nginx\\/error.log/g" /etc/nginx/nginx.conf
sed -i "s/access_log\s\+logs\\/access.log/access_log \\/var\\/log\\/nginx\\/access.log/g" /etc/nginx/nginx.conf
sed -i "s/sendfile\s\+on;/sendfile        off;\n\n  types_hash_max_size 2048;\n  server_names_hash_bucket_size 64;/g" /etc/nginx/nginx.conf
sed -i "s/access_log\s\+logs\\/static.log/access_log \\/var\\/log\\/nginx\\/static.log/g" /etc/nginx/h5bp/location/expires.conf
touch /var/log/nginx/static.log

# Create `logs` directory
su - vagrant -c "rm -rf /vagrant/logs && mkdir -p /vagrant/logs"

# Download the latest version of WordPress into the `public` directory
su - vagrant -c "cd /tmp && wget http://wordpress.org/latest.tar.gz && tar -xzvf latest.tar.gz && rsync -r wordpress/* /vagrant/public && rm /tmp/latest.tar.gz && rm -rf /tmp/wordpress"

# Configure default site using http.conf
rm /etc/nginx/sites-available/*
ln -s /vagrant/.provision/http.conf /etc/nginx/sites-available/default
ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

# Create udev rules to run the startup script after vagrant shared folder is mounted
cat > /etc/udev/rules.d/50-vagrant-mount.rules << _EOF_
SUBSYSTEM=="bdi",ACTION=="add",RUN+="/usr/bin/screen -m -d /bin/bash -c 'sleep 5; /vagrant/.provision/bootstrap'"
_EOF_

# Bootstrap after vagrant up
/vagrant/.provision/bootstrap

# Restart nginx
service nginx restart

# Create database
mysql -u $DB_USER -p$MYSQL_ROOT_PASS -e "CREATE DATABASE $DB_NAME"
