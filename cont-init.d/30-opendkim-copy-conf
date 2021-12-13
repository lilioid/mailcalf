#!/bin/sh
set -e

cp /app/conf/opendkim_domains.txt /etc/opendkim/domains.txt
cp /app/conf/opendkim_key.pem /etc/opendkim/key.pem

chown -R opendkim:opendkim /etc/opendkim
chmod -R u=rwX,g=r,o= /etc/opendkim
