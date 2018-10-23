# Run the latest Moodle on Ubuntu 18.04.1 LTS, includes

- Shell In A Box – A Web-Based SSH Terminal - version 2.x
- nginx version: nginx/1.x
- php-fpm 7.0.x
- mysql version 5.7.x
- phpMyAdmin latest version
- composer latest version
- You can also handle all services using supervisord 3. <container_ip>:9011 or commandline:

```bash
moodle@c9786d14b245:~/files/html$ sudo supervisorctl
Cron                             RUNNING   pid 20, uptime 1:30:39
MySQL                            RUNNING   pid 14, uptime 1:30:39
NGINX                            RUNNING   pid 15, uptime 1:30:39
PHP-FPM                          RUNNING   pid 13, uptime 1:30:39
System-Log                       RUNNING   pid 19, uptime 1:30:39
```

___

## Usage

Services and ports exposed

- MySQL - <container_ip>:3306
- phpMyAdmin - http://<container_ip>/phpmyadmin
- Nginx and php-fpm 7.0.x - http://<container_ip> and https://<container_ip> for web browsing

### Sample container initialization

```bash
$ docker run -v <your-webapp-root-directory>:/home/moodle/files -p 9022:9011 --name docker-name -d thomasvan/ubuntu18-moodle-nginx-php7-mysql-phpmyadmin-supervisord:latest
```

___

After starting the container ubuntu18-moodle-nginx-php7-mysql-phpmyadmin-composer, please check to see if it has started and the port mapping is correct. This will also report the port mapping between the docker container and the host machine.

### Accessing containers by port mapping

```bash
$ docker ps

0.0.0.0:9011->9022/tcp
```

___

You can start/stop/restart and view the error logs of nginx and php-fpm services: `http://127.0.0.1:9022`

### Accessing containers by internal IP

_For Windows 10, you need to [add route: route add 172.17.0.0 MASK 255.255.0.0 10.0.75.2](https://forums.docker.com/t/connecting-to-containers-ip-address/18817/13) manually before using one of the following ways to get internal IP:_

- Looking into the output of `docker logs <container-id>`:
- Using [docker inspect](https://docs.docker.com/engine/reference/commandline/inspect/parent-command) command

___

```bash
c9786d14b245 login: moodle
Password:
Welcome to Ubuntu 18.04.1 LTS ...

moodle@c9786d14b245:~$ cat ~/readme.txt
IP Address : 172.17.0.2
Web Directory : /home/moodle/files/html
SSH/SFTP User : moodle/moodle
ROOT User : root/root
Database Host : localhost
Database Name : moodle
Database User : moodle/moodle
DB ROOT User : root/root 
phpMyAdmin : https://172.17.0.2/phpmyadmin
```

___

_Now as you've got all that information, you can set up moodle and access the website via IP Address or creating an [alias in hosts](https://support.rackspace.com/how-to/modify-your-hosts-file/) file_

```bash
c9786d14b245 login: moodle
Password:
Welcome to Ubuntu 18.04.1 LTS ...

moodle@c9786d14b245:~$ cd files/html/
moodle@c9786d14b245:~/files/html$ echo "install moodle here..."
install moodle here...
moodle@c9786d14b245:~/files/html$ echo "all set, you can browse your website now"
all set, you can browse your website now
moodle@c9786d14b245:~/files/html$ 
   ```

___

_If anyone has suggestions please leave a comment on [this GitHub issue](https://github.com/thomasvan/ubuntu18-moodle-nginx-php7/issues/2)._

_Requests? Just make a comment on [this GitHub issue](https://github.com/thomasvan/ubuntu18-moodle-nginx-php7/issues/1) if there's anything you'd like added or changed._