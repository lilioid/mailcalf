FROM docker.io/elixir:latest

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update &&\
    apt-get install -y --no-install-recommends inotify-tools dovecot-core dovecot-imapd dovecot-lmtpd dovecot-managesieved dovecot-sieve postfix &&\
    rm -rf /etc/dovecot &&\
    mkdir /etc/dovecot &&\
    chown -R root:dovecot /etc/dovecot
RUN apt-get install -y vim less

RUN mix local.hex --force &&\
    mix local.rebar --force

ADD docker/elixir_wrap_program.sh /usr/local/bin/elixir_wrap_program.sh
VOLUME /usr/local/src/mailcalf
WORKDIR /usr/local/src/mailcalf/src
