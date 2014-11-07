#vim:set ft=dockerfile:
FROM debian:wheezy
MAINTAINER Robert Vally <robert@vally.co.nz>

# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
RUN apt-get update \
    && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

# Install dovecot and related packages
RUN apt-get update \
    && apt-get install -y \
        dovecot-core dovecot-imapd dovecot-lmtpd dovecot-pgsql

# Install postfix
RUN apt-get update \
    && apt-get install -y postfix postfix-pgsql

# Push updated dovecot configuration
ADD ./dovecot.conf /etc/dovecot/dovecot.conf
ADD ./dovecot-sql.conf.ext /etc/dovecot/dovecot-sql.conf.ext
ADD ./10-mail.conf /etc/dovecot/conf.d/10-mail.conf
ADD ./10-auth.conf /etc/dovecot/conf.d/10-auth.conf
ADD ./10-master.conf /etc/dovecot/conf.d/10-master.conf
ADD ./10-ssl.conf /etc/dovecot/conf.d/10-ssl.conf
ADD ./15-lda.conf /etc/dovecot/conf.d/15-lda.conf
ADD ./auth-sql.conf.ext /etc/dovecot/conf.d/auth-sql.conf.ext

RUN groupadd -g 5000 vmail
RUN useradd -g vmail -u 5000 vmail -d /var/mail
RUN chown -R vmail:dovecot /etc/dovecot
RUN chmod -R o-rwx /etc/dovecot

# Push postfix configuration
ADD ./postfix-main.cf /etc/postfix/main.cf
ADD ./postfix-master.cf /etc/postfix/master.cf
ADD ./pgsql-virtual-mailbox-domains.cf /etc/postfix/pgsql-virtual-mailbox-domains.cf
ADD ./pgsql-virtual-mailbox-maps.cf /etc/postfix/pgsql-virtual-mailbox-maps.cf
ADD ./pgsql-virtual-alias-maps.cf /etc/postfix/pgsql-virtual-alias-maps.cf

# We need syslog because that is where dovecot puts everything
RUN apt-get update && apt-get install -y rsyslog

VOLUME ["/var/mail"]
EXPOSE 993
EXPOSE 587
EXPOSE 25

# TODO: Managed processes with supervisor and redirect logs to stdout
ENTRYPOINT chown -R vmail:vmail /var/mail; service rsyslog start; service postfix start; dovecot -F
