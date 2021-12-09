#!/bin/sh
set -e
PROG=$(basename $0)

if [ -r /app/conf/postfix_local.cf ]; then
  echo "[$PROG] Appending /app/conf/postfix_local.cf to /etc/postfix/main.cf"
  cat /app/conf/postfix_local.cf >> /etc/postfix/main.cf
fi
