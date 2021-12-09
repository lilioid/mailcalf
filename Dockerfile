FROM docker.io/debian:11-slim

# install s6 init system
ARG S6_VERSION="v2.2.0.1"
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer /
ENTRYPOINT ["/init"]

# install required software
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update &&\
    apt-get install -y --no-install-recommends ca-certificates \
      postfix \
      dovecot-core dovecot-imapd dovecot-lmtpd dovecot-sieve dovecot-managesieved dovecot-auth-lua \
      lua-http lua-json  \
      redis-server \
      rspamd && \
    ln -s /usr/share/lua/5.2/lpeg_patterns/ /usr/share/lua/5.3/lpeg_patterns && \
    ln -s /usr/share/lua/5.2/basexx.lua /usr/share/lua/5.3/basexx.lua && \
    ln -s /usr/share/lua/5.2/fifo.lua /usr/share/lua/5.3/fifo.lua && \
    rm -rf /var/lib/apt/lists/* /etc/dovecot
COPY base64.lua /usr/share/lua/5.3/

# configure container
COPY services.d /etc/services.d/
COPY cont-init.d /etc/cont-init.d/
COPY dovecot /etc/dovecot/
COPY postfix /etc/postfix/
COPY rspamd /etc/rspamd/

# configure image metadata
# smtp
EXPOSE 25/tcp
# submission
EXPOSE 587/tcp
# imap
EXPOSE 993/tcp
# rspamd admin interface
EXPOSE 11334/tcp
VOLUME /app/conf
VOLUME /app/ssl
VOLUME /app/mail
VOLUME /app/data
CMD ["cat", "-"]
