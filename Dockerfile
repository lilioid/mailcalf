FROM docker.io/debian:12-slim

# install required software
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update &&\
    apt-get install -y --no-install-recommends ca-certificates \
      postfix \
      dovecot-core dovecot-imapd dovecot-lmtpd dovecot-sieve dovecot-managesieved \
      redis-server \
      rspamd \
      opendkim opendkim-tools \
      fetchmail \
      xz-utils && \
    rm -rf /var/lib/apt/lists/* /etc/dovecot /etc/opendkim.conf

# install s6 init system
ARG S6_VERSION="v3.1.5.0"
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
ENTRYPOINT ["/init"]

# configure container
COPY s6-rc.d /etc/s6-overlay/s6-rc.d
RUN rm -r /etc/s6-overlay/s6-rc.d/user/contents.d
COPY dovecot /etc/dovecot/
RUN chmod +x /etc/dovecot/sieve_extprograms/*
RUN find /etc/dovecot/sieve -name \*.sieve -exec sievec {} \;
COPY postfix /etc/postfix/
COPY rspamd /etc/rspamd/
COPY opendkim/ /etc/opendkim

# configure image metadata
# smtp
EXPOSE 25/tcp
EXPOSE 26/tcp
# submission
EXPOSE 587/tcp
# imap
EXPOSE 993/tcp
# rspamd admin interface
EXPOSE 11334/tcp
# sieve-manager
EXPOSE 4190/tcp
VOLUME /app/conf
VOLUME /app/ssl
VOLUME /app/mail
VOLUME /app/data
