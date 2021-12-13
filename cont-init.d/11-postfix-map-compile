#!/bin/sh
set -e

PROG=$(basename $0)

for i in "virtual_alias_maps" "virtual_domains" "sender_login_maps"; do
  echo "[$PROG] processing $i"
  cp "/app/conf/postfix_$i.txt" "/etc/postfix/$i" &&\
  postmap "/etc/postfix/$i"
done
