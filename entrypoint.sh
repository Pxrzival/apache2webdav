#!/bin/bash -e

printf "########################################\n"
printf "# Container starting up!\n"
printf "########################################\n"

# Check for WebDAV user/pass for Digest Authentication
printf "# STATE: Checking for WebDav user/pass\n"
if [ -n "$WEBDAV_USER" ] && [ -n "$WEBDAV_PASS" ]
then
    printf "# STATE: WebDav user/pass written to /etc/apache2/webdav_credentials\n"
    htdigest -c /etc/apache2/webdav_credentials "Restricted" $WEBDAV_USER $WEBDAV_PASS > /dev/null 2>&1
else
    printf "# WARN: No WebDav user/pass were set, the \"restricted\" directory has no authentication!\n"
    sed -i "s/.*AuthType Digest.*//g" /etc/apache2/sites-enabled/webdav.conf
    sed -i "s/.*AuthName.*//g" /etc/apache2/sites-enabled/webdav.conf
    sed -i "s/.*AuthUserFile.*//g" /etc/apache2/sites-enabled/webdav.conf
    sed -i "s/.*Require valid-user.*//g" /etc/apache2/sites-enabled/webdav.conf
fi

# Check for client_max_body_size equivalent for Apache (LimitRequestBody)
if [ -n "$APACHE_CLIENT_MAX_BODY_SIZE" ]
then
    printf "# STATE: Setting client_max_body_size (LimitRequestBody) to $APACHE_CLIENT_MAX_BODY_SIZE\n"
    sed -i "s/LimitRequestBody 262144000/LimitRequestBody $APACHE_CLIENT_MAX_BODY_SIZE/g" /etc/apache2/sites-enabled/webdav.conf
fi

printf "# STATE: Apache is starting up now, the logs you see below are error_log and access_log from Apache\n"

# Start Apache in the foreground
exec "$@"
