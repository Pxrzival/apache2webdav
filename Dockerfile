# Use the official Debian image
FROM debian:12-slim

ARG BUILD_DATE

ARG DEBIAN_FRONTEND=noninteractive

# Install Apache2 and the necessary WebDAV modules
RUN apt-get update && apt-get -y install --no-install-recommends \
    apache2 \
    apache2-utils \
    netcat-openbsd && \
    rm -rf /var/lib/apt/lists/*

# Enable necessary Apache modules
RUN a2enmod dav dav_fs dav_lock auth_digest remoteip && \
    mkdir -p "/var/www/webdav/public" && \
    mkdir -p "/var/www/webdav/restricted" && \
    touch /var/www/webdav/DavLock && \
    chown -R www-data:www-data /var/www/webdav && \
    rm /etc/apache2/sites-enabled/000-default.conf

# Expose port 80
EXPOSE 80

# Define the WebDAV configuration file
COPY webdav.conf /etc/apache2/sites-enabled/webdav.conf

# Create a volume for the WebDAV data
VOLUME [ "/var/www/webdav" ]

# Copy the entrypoint script
COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh

RUN echo "ServerName storage.hiemercloud.de" >> /etc/apache2/apache2.conf

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Start Apache in the foreground
CMD ["apachectl", "-D", "FOREGROUND"]

# Healthcheck to ensure the server is running
HEALTHCHECK CMD nc -z localhost 80 || exit 1
