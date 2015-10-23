## Installation

Run `vagrant up` which will setup the server for the first time and perform provisioning by installing all necessary software.

	vagrant up

## Host File Configuration

Edit the host file on client computer (i.e. `/etc/hosts` on Mac OS X).

	sudo nano /etc/hosts

Add the following line:

	192.168.50.100 mysite.dev www.mysite.dev

Now both of the following URLs should point to the same location:

- [`http://mysite.dev/`](http://mysite.dev/)
- [`http://www.mysite.dev/`](http://www.mysite.dev/)
