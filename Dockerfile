FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Tor, Nginx, and Curl
RUN apt-get update && apt-get install -y \
    tor \
    nginx \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configure Nginx on port 10000
RUN echo 'server { \
    listen 10000; \
    location / { \
        proxy_pass https://YOUR-WORKER-SUBDOMAIN.workers.dev; \
        proxy_set_header Host YOUR-WORKER-SUBDOMAIN.workers.dev; \
        proxy_ssl_server_name on; \
        proxy_ssl_protocols TLSv1.2 TLSv1.3; \
    } \
}' > /etc/nginx/sites-available/default

# Configure Tor hidden service
RUN echo 'HiddenServiceDir /var/lib/tor/my_onion_site/' >> /etc/tor/torrc && \
    echo 'HiddenServicePort 80 127.0.0.1:10000' >> /etc/tor/torrc

# Fix permissions for Tor hidden service directory
RUN mkdir -p /var/lib/tor/my_onion_site && \
    chown -R debian-tor:debian-tor /var/lib/tor/my_onion_site && \
    chmod 700 /var/lib/tor/my_onion_site

EXPOSE 10000

# Start Nginx in background, run Tor daemon, wait for address generation, print address to logs
CMD nginx && \
    su -s /bin/bash debian-tor -c "tor" & \
    sleep 15 && \
    cat /var/lib/tor/my_onion_site/hostname && \
    tail -f /dev/null
