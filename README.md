Installation
------------

First run `vagrant up` which will setup the server for the first time and perform provisioning by installing all necessary software.

	cd /path/to/project/dir
	vagrant up

Reboot the server so that `upstart` kicks-off nginx at startup.

	vagrant reload

Now browse to `http://192.168.50.100/`. And you should see an "Awesome!" message.
