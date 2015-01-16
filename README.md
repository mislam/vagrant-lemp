## Installation

Run `vagrant up` which will setup the server for the first time and perform provisioning by installing all necessary software.

	vagrant up

### Reboot

Reboot the server so that `upstart` kicks-off nginx at startup.

	vagrant reload

Now browse to [`http://192.168.50.100/`](http://192.168.50.100/).


## Host File Configuration

Instead of accessing the website from the IP address, let's access it from `mysite.dev`. Edit the host file on client computer (on Mac OS X, it's `/etc/hosts`)

	sudo nano /etc/hosts

Add the following line:

	192.168.50.100    mysite.dev
