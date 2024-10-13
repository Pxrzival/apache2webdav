#!/bin/bash

# Enable debug mode and print each command before executing
set -x

printf "########################################\n"
printf "# Container starting up!\n"
printf "########################################\n"

# Check for WebDav user/pass
printf "# STATE: Checking for WebDav user/pass\n"
if [ -n "$WEBDAV_USER" ] && [ -n "$WEBDAV_PASS" ]; then
    if [ ! -f /etc/apache2/webdav_credentials ]; then
        printf "# STATE: WebDav credentials file does not exist, creating it...\n"
        htdigest -c /etc/apache2/webdav_credentials "Restricted" "$WEBDAV_USER" "$WEBDAV_PASS" 2>&1
    else
        printf "# STATE: WebDav credentials file exists, adding/updating user...\n"
        htdigest /etc/apache2/webdav_credentials "Restricted" "$WEBDAV_USER" "$WEBDAV_PASS" 2>&1
    fi
else
    printf "# WARN: No WebDav user/pass were set, the \"restricted\" directory has no authentication!\n"
    sed -i "s/.*AuthType Digest.*//g" /etc/apache2/sites-enabled/webdav.conf
    sed -i "s/.*AuthName.*//g" /etc/apache2/sites-enabled/webdav.conf
    sed -i "s/.*AuthUserFile.*//g" /etc/apache2/sites-enabled/webdav.conf
    sed -i "s/.*Require valid-user.*//g" /etc/apache2/sites-enabled/webdav.conf
fi

# Check for client_max_body_size equivalent for Apache (LimitRequestBody)
if [ -n "$APACHE_CLIENT_MAX_BODY_SIZE" ]; then
    printf "# STATE: Setting client_max_body_size (LimitRequestBody) to $APACHE_CLIENT_MAX_BODY_SIZE\n"
    sed -i "s/LimitRequestBody 262144000/LimitRequestBody $APACHE_CLIENT_MAX_BODY_SIZE/g" /etc/apache2/sites-enabled/webdav.conf
fi

# Run Apache configuration test to check for any issues
printf "# STATE: Running Apache configtest\n"
apachectl configtest 2>&1

printf "# STATE: Apache is starting up now, the logs you see below are error_log and access_log from Apache\n"

# Start Apache in the foreground
exec apachectl -D FOREGROUND
