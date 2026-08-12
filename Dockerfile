FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    tor \
    nginx \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configure Nginx to disable port appending in redirects
RUN echo 'server { \
    listen 10000; \
    port_in_redirect off; \
    location / { \
        proxy_pass https://jmtc-proxy.ryan-shami.workers.dev; \
        proxy_set_header Host jmtc-proxy.ryan-shami.workers.dev; \
        proxy_set_header X-Forwarded-Host $http_host; \
        proxy_set_header X-Forwarded-Port 80; \
        proxy_set_header X-Forwarded-Proto http; \
        proxy_ssl_server_name on; \
        proxy_ssl_protocols TLSv1.2 TLSv1.3; \
        proxy_redirect https://jmtc-proxy.ryan-shami.workers.dev/ /; \
    } \
}' > /etc/nginx/sites-available/default

# Configure Tor hidden service
RUN echo 'HiddenServiceDir /var/lib/tor/my_onion_site/' >> /etc/tor/torrc && \
    echo 'HiddenServicePort 80 127.0.0.1:10000' >> /etc/tor/torrc

# Fix permissions
RUN mkdir -p /var/lib/tor/my_onion_site && \
    chown -R debian-tor:debian-tor /var/lib/tor/my_onion_site && \
    chmod 700 /var/lib/tor/my_onion_site

EXPOSE 10000

# Start Nginx, schedule address print in background, and launch Tor in foreground
CMD nginx && \
    (sleep 12 && cat /var/lib/tor/my_onion_site/hostname) & \
    su -s /bin/bash debian-tor -c "tor"
