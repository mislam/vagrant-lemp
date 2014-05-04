## Installation

First run `vagrant up` which will setup the server for the first time and perform provisioning by installing all necessary software.

	cd /path/to/project/dir
	vagrant up

Reboot the server so that `upstart` kicks-off nginx at startup.

	vagrant reload

Now browse to [`http://192.168.50.100/`](http://192.168.50.100/).


## Host File Configuration

Instead of accessing the website from the IP address, let's access it from `mysite.dev`. Edit the host file on client computer (on Mac OS X, it's `/etc/hosts`)

	sudo nano /etc/hosts

Add the following line:

	192.168.50.100    mysite.dev


## Database Backup

To create a database snapshot, issue the following command from the VM. This will store the backup file under `db` directory.

	vagrant ssh
	mysqldump -u root -pmysite mysite > /vagrant/db/mysite.sql

To restore from a previous snapshot:

	mysql -u root -pmysite mysite < /vagrant/db/mysite.sql
