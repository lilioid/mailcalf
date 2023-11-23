FROM docker.io/elixir:latest

RUN apt-get update &&\
    apt-get install -y --no-install-recommends inotify-tools dovecot-core dovecot-imapd dovecot-lmtpd dovecot-managesieved dovecot-sieve

RUN mix local.hex --force

ADD docker/elixir_wrap_program.sh /usr/local/bin/elixir_wrap_program.sh
VOLUME /usr/local/src/mailcalf
WORKDIR /usr/local/src/mailcalf/src
