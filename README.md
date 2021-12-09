# Dockerized Mailserver

This mailserver accepts the following configurations

- `/app/conf/dovecot_local.conf`
  A dovecot configuration file that is automatically included at the end of the container's configuration.
    - [Dovecot Documentation Reference](https://doc.dovecot.org/)

- `/app/conf/postfix_local.cf`
  A postfix `main.cf` file that is automatically appended to the container's configuration.
    - [Postfix Documentation Reference](http://www.postfix.org/documentation.html)
    - [All main.cf parameters](http://www.postfix.org/postconf.5.html)

- `/app/conf/keycloak_auth.json`
  A json file which is used to configure Keycloack authentication for dovecot.

  The expected structure looks like this:
  ```json
  {
    "keycloak_url": "https://keycloak.finn-thorben.me",
    "keycloak_realm": "sharedsrv",
    "keycloak_client_id": "mailserver",
    "keycloak_client_secret": "<secret>"
  }
  ```

  The corresponding client configuration in keycloak needs to have *Direct Access Grants* and *Service Accounts*
  enabled in order to work properly.

- `/app/conf/postfix_virtual_alias_maps.txt`
  A berkeley db table which lists email address aliases ([Postfix reference](http://www.postfix.org/postconf.5.html#virtual_alias_maps)).

  This basically means one alias per line in a `<from> <to>` format.
  These aliases can be recursive.

  For mails to be correctly deliverable, all aliases should finally resolve to a keycloak username.

- `/app/conf/rspamd_worker_controller.inc`
  Incrementally applied configuration file for *rspamd*.

  It should at least set the following parameters:
  ```
  password = "$2$z4y5epzqj6jxzrkxca4wb4tszfnhmtcs$39tgkjx95srtw4mu9ey5fcxrn6yq4wsqy5z4eqxwijzbas9kq7wb";
  ``` 

- `/app/ssl/tls.crt` and `/app/ssl/tls.key` for TLS encryption.
