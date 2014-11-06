#vim:set ft=dockerfile:
FROM nginx
MAINTAINER Robert Vally <robert@vally.co.nz>

RUN apt-get update && apt-get install -y php5-fpm php5-mcrypt php5-intl \
                                         php5-sqlite wget

RUN mkdir -p /srv/http /var/lib/roundcube
ADD roundcubemail-1.0.3.tar.gz /srv/http
RUN mv /srv/http/roundcubemail-1.0.3 /srv/http/roundcube
#RUN tar xf /tmp/roundcubemail-1.0.3.tar.gz -C /srv/http/roundcube --strip-components=1
#RUN rm -rf /srv/http/roundcube/installer

ENV ROUNDCUBE_VERSION 1.0.3

ADD nginx.conf /etc/nginx/nginx.conf
ADD config.inc.php /srv/http/roundcube/config/config.inc.php
RUN chown -R www-data:www-data /var/lib/roundcube 

RUN chown www-data:www-data -R /srv/http
#TODO: redirect roundcube errors to stdout

VOLUME ["/var/lib/roundcube"]

CMD chown -R www-data:www-data /var/lib/roundcube; /usr/sbin/service php5-fpm start; /usr/sbin/nginx -g "daemon off;"
