FROM ubuntu:18.04
LABEL maintainer="Thomas Van<thomas@forixdigital.com>"

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl && \
    ln -sf /bin/true /sbin/initctl && \
    mkdir /var/run/sshd && \
    mkdir /run/php && \
    mkdir /var/run/mysqld

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y software-properties-common && \
    LC_ALL=C.UTF-8 add-apt-repository -y -u ppa:ondrej/php


# Basic Requirements
RUN apt-get -y install python-setuptools curl git nano sudo unzip openssh-server openssl
RUN apt-get -y install mysql-server php7.0-fpm

# Moodle Requirements
RUN apt-get -y install graphviz aspell php7.0-pspell php7.0-curl php7.0-gd php7.0-intl php7.0-mysql php7.0-xmlrpc php7.0-ldap php7.0-zip php7.0-mbstring php7.0-soap php7.0-xml 

# MySQL config
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/explicit_defaults_for_timestamp = true\nbind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# nginx config
RUN apt-get -y install nginx && \
    sed -i -e"s/user\s*www-data;/user moodle www-data;/" /etc/nginx/nginx.conf && \
    sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf && \
    sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf && \
    echo "daemon off;" >> /etc/nginx/nginx.conf

# php-fpm config
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php/7.0/fpm/php.ini && \
    sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php/7.0/fpm/php.ini && \
    sed -i -e "s/memory_limit\s*=\s*128M/memory_limit = 2048M/g" /etc/php/7.0/fpm/php.ini && \
    sed -i -e "s/max_execution_time\s*=\s*30/max_execution_time = 3600/g" /etc/php/7.0/fpm/php.ini /etc/php/7.0/cli/php.ini && \
    sed -i -e "s/;\s*max_input_vars\s*=\s*1000/max_input_vars = 36000/g" /etc/php/7.0/fpm/php.ini /etc/php/7.0/cli/php.ini && \
    sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf && \
    sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i -e "s/user\s*=\s*www-data/user = moodle/g" /etc/php/7.0/fpm/pool.d/www.conf

# nginx site conf
ADD conf/nginx-site.conf /etc/nginx/sites-available/default
RUN mkdir /etc/nginx/moodle-conf.d
ADD conf/nginx-moodle.conf /etc/nginx/moodle-conf.d

# Generate self-signed ssl cert
RUN mkdir /etc/nginx/ssl/
RUN openssl req \
    -new \
    -newkey rsa:4096 \
    -days 365 \
    -nodes \
    -x509 \
    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=localhost" \
    -keyout /etc/ssl/private/ssl-cert-snakeoil.key \
    -out /etc/ssl/certs/ssl-cert-snakeoil.pem

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Supervisor Config
RUN apt-get install -y supervisor
ADD conf/supervisord.conf /etc/supervisord.conf

# Add system user for Moodle
RUN useradd -m -d /home/moodle -p $(openssl passwd -1 'moodle') -G root -s /bin/bash moodle \
    && usermod -a -G www-data moodle \
    && usermod -a -G sudo moodle \
    && mkdir -p /home/moodle/files/html \
    && chown -R moodle: /home/moodle/files \
    && chmod -R 775 /home/moodle/files

# Generate private/public key for "moodle" user
RUN sudo -H -u moodle bash -c 'echo -e "\n\n\n" | ssh-keygen -t rsa'


# phpMyAdmin
RUN curl --location https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz | tar xzf - && \
    mv phpMyAdmin* /usr/share/phpmyadmin
ADD conf/config.inc.php /usr/share/phpmyadmin/config.inc.php
RUN chown -R moodle: /usr/share/phpmyadmin

# Moodle cron and startup Script
COPY conf/moodle.cron /tmp/
ADD ./start.sh /start.sh

RUN crontab -u moodle /tmp/moodle.cron && \
    chmod 755 /start.sh && \
    chown mysql:mysql /var/run/mysqld

#NETWORK PORTS
# private expose
EXPOSE 9011
EXPOSE 3306

# volume for mysql database and moodle install
VOLUME ["/var/lib/mysql", "/home/moodle/files"]
CMD ["/bin/bash", "/start.sh"]
