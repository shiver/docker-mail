FROM ubuntu:14.04
MAINTAINER Robert Vally <robert@vally.co.nz>

ENV DOMAIN example.com
ENV APT_MIRROR mirror.webhost.co.nz

# Replace ubuntu apt with mirror of choice
RUN sed -r -i.bak -e 's/(deb\s)(.*)(archive.ubuntu.com)(.*)/\1\2mirror.webhost.co.nz\4/g' /etc/apt/sources.list

# Start of "s0" which purely fetches most of the packages we'll be needing
# throughout the install and also installs the base mail-stack-delivery
# package

RUN apt-get update 
#RUN sudo apt-get upgrade
RUN apt-get install -y aptitude wget software-properties-common

# Some PPAs we'll need for more up-to-date software
RUN add-apt-repository ppa:malte.swart/dovecot-2.2
RUN add-apt-repository ppa:nginx/development
#RUN add-apt-repository ppa:ondrej/php5
RUN aptitude update

RUN echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
RUN echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
RUN echo mariadb-server-5.5 mysql-server/root_password password changeme | debconf-set-selections
RUN echo mariadb-server-5.5 mysql-server/root_password_again password changeme | debconf-set-selections

RUN DEBIAN_FRONTEND=noninteractive aptitude install -y opendkim opendkim-tools spamass-milter pyzor razor \
libmail-dkim-perl iptables-persistent nginx-full mariadb-server php5-fpm \
php5-mysqlnd php-pear php5-mcrypt php5-intl 

## End of s0

## Start of s1

#RUN wget http://sourceforge.net/projects/roundcubemail/files/roundcubemail/1.0.0/roundcubemail-1.0.0.tar.gz/download -O /usr/share/nginx/roundcubemail-1.0.0.tar.gz

#RUN aptitude upgrade

# Installation configuration for mail-stack-delivery
# Postfix
#RUN echo postfix postfix/main_mailer_type select "Internet Site" | debconf-set-selections
#RUN echo postfix postfix/mailname string ${DOMAIN} | debconf-set-selections
## Dovecot
#RUN echo dovecot-core dovecot-core/ssl-cert-name string localhost | debconf-set-selections
#RUN echo dovecot-core dovecot-core/create-ssl-cert boolean false | debconf-set-selections
## SSL
#RUN echo ssl-cert make-ssl-cert/hostname string localhost | debconf-set-selections
#
## Install mail-stack-delivery
#RUN DEBIAN_FRONTEND=noninteractive aptitude install -y -q mail-stack-delivery
# End of "s0"

# Start of "s1"

# Virtual mail
#RUN groupadd -g 5000 vmail
#RUN useradd -g vmail -u 5000 vmail -d /var/mail/vmail -m
#
## SSL Setup
#RUN cd /etc/ssl/private && wget https://www.startssl.com/certs/sub.class1.server.ca.pem
## cat ssl-cert-mail-yourdomain.pem sub.class1.server.ca.pem > ssl-chain-mail-yourdomain.pem
## openssl rsa -in ssl-key-encrypted-mail-yourdomain.key -out ssl-key-decrypted-mail-yourdomain.key
## chown root:root ssl-key-*
## chmod 400 ssl-key-*
#
## OpenDKIM
##RUN aptitude install opendkim opendkim-tools
#RUN mkdir /etc/opendkim && chown opendkim:opendkim /etc/opendkim
#RUN cd /etc/opendkim && opendkim-genkey -r -h shad256 -d mail.example.com -s mail
#RUN mv mail.private mail
#RUN echo mail.${DOMAIN}.com mail.${DOMAIN}.com:mail:/etc/opendkim/mail >> /etc/opendkim/KeyTable
#RUN echo *@${DOMAIN} mail.${DOMAIN} >> /etc/opendkim/KeyTable
#RUN echo 127.0.0.1 >> /etc/opendkim/TrustedHosts
#RUN chown -R opendkim:opendkim /etc/opendkim
#RUN mkdir /var/spool/postfix/opendkim
#RUN chown opendkim:root /var/spool/postfix/opendkim
#RUN service opendkim restart
#RUN usermod -G opendkim postfix
#
## SpamAssassin
##RUN aptitude install spamass-milter pyzor razor libmail-dkim-perl
#RUN adduser --shell /bin/false --home /var/lib/spamassassin --disabled-password --disabled-login --gecos "" spamd
#RUN usermod -a -G spamd spamass-milter
#RUN mkdir /var/spool/postfix/spamassassin
#RUN chown spamd:root /var/spool/postfix/spamassassin/
#
## Roundcube
#RUN cd /usr/share/nginx/ && tar zxfv roundcubemail-1.0.0.tar.gz
#RUN rm -rf /usr/share/nginx/roundcube
#RUN mv /usr/share/nginx/roundcubemail-1.0.0 /usr/share/nginx/roundcube
#RUN chown -R www-data:www-data /usr/share/nginx/roundcube
#RUN cd /usr/share/nginx/roundcube/plugins && git clone https://github.com/alexandregz/twofactor_gauthenticator.git
#RUN chown -R www-data:www-data /usr/share/nginx/roundcube/plugins
#
