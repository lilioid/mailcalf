# Dockerized Mailserver

This mailserver accepts the following configurations

- `/app/conf/dovecot_local.conf`
  A dovecot configuration file that is automatically included at the end of the container's configuration.
    - [Dovecot Documentation Reference](https://doc.dovecot.org/)

- `/app/conf/postfix_local.cf`
  A postfix `main.cf` file that is automatically appended to the container's configuration.
    - [Postfix Documentation Reference](http://www.postfix.org/documentation.html)
    - [All main.cf parameters](http://www.postfix.org/postconf.5.html)

- `/app/conf/dovecot-oauth2.conf.ext`
  A json file which is used to configure Oauth2 password grant authentication.

  Using this mechanism, it is possible to authenticate users via the SMTP/IMAP `PLAIN` or `LOGIN` schemes by passing
  the password through to an oauth server supporting direct access grant.

  The expected structure looks like this the following but more parameters are described in the [Dovecot Oauth2 documentation](https://doc.dovecot.org/configuration_manual/authentication/oauth2/):
  ```
  debug = no
  grant_url = <the token endpoint>
  introspection_url = <the token introspection endpoint>
  client_id = <oauth2 client id>
  client_secret = <oauth2 client secret>
  introspection_mode = post
  use_grant_password = yes
  username_attribute = preferred_username
  ```

  The corresponding client configuration in keycloak needs to have *Direct Access Grants* and *Service Accounts*
  enabled in order to work properly.

- `/app/conf/postfix_virtual_alias_maps.txt`
  A berkeley db table which lists email address aliases ([Postfix reference](http://www.postfix.org/postconf.5.html#virtual_alias_maps)).

  This basically means one alias per line in a `<from> <to>` format.
  These aliases can be recursive.

  For mails to be correctly deliverable, all aliases should finally resolve to a keycloak username.

- `/app/conf/postfix_virtual_domains.txt`
  A berkeley db table which lists domains for which this server accepts mails.

  The right-hand side of the table is completely ignored and can be anything.

- `/app/conf/postfix_sender_login_maps.txt`
  A lookup table that specifies which user is allowed to send from which address.

  [Postfix Documentation](http://www.postfix.org/postconf.5.html#smtpd_sender_login_maps)

- `/app/conf/postfix_recipient_access.txt`
  A lookup table from which postfix determines specific actions that it performs depending on the resolved recipient address.

  [Postfix Documentation](http://www.postfix.org/access.5.html)

- `/app/conf/rspamd_worker_controller.inc`
  Incrementally applied configuration file for *rspamd*.

  It should at least set the following parameters:
  ```
  password = "$2$z4y5epzqj6jxzrkxca4wb4tszfnhmtcs$39tgkjx95srtw4mu9ey5fcxrn6yq4wsqy5z4eqxwijzbas9kq7wb";
  ``` 

- `/app/conf/opendkim_domains.txt`
  A file listing the domains which will be dkim signed.

- `/app/conf/opendkim_key.pem`
  The private key with which dkim signatures will be made.

- `/app/ssl/tls.crt` and `/app/ssl/tls.key` for TLS encryption.

- `/app/conf/dovecot-extra.passwd` for extra users in addition to OAuth2 login.

  The format is `<username>:<password>` where the password is encrypted.
  An encryption with the configured format can be done using the `doveadm pw` CLI utility.

- `/app/conf/fetchmailrc` for configuring fetchmail. See the 
  [documentation](https://www.fetchmail.info/fetchmail-man.html#keyword-option-summary) for the syntax of this file.

  Delivery options can be ignored in the config file as they are set as command line arguments to fetchmail by the 
  container (see the [launch script](./s6-rc.d/fetchmail/run) for details). 

  The file could for example look like this:
  ```
  poll imap.mydomain.de protocol IMAP auth password
    user "ftsell" with password "…" is "ftsell" here
  ```
