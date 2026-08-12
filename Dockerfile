FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    tor \
    nginx \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN echo 'server { \
    listen 10000; \
    location / { \
        proxy_pass https://YOUR-WORKER-SUBDOMAIN.workers.dev; \
        proxy_set_header Host YOUR-WORKER-SUBDOMAIN.workers.dev; \
        proxy_ssl_server_name on; \
        proxy_ssl_protocols TLSv1.2 TLSv1.3; \
    } \
}' > /etc/nginx/sites-available/default

RUN echo 'HiddenServiceDir /var/lib/tor/my_onion_site/' >> /etc/tor/torrc && \
    echo 'HiddenServicePort 80 127.0.0.1:10000' >> /etc/tor/torrc

RUN mkdir -p /var/lib/tor/my_onion_site && \
    chown -R debian-tor:debian-tor /var/lib/tor/my_onion_site && \
    chmod 700 /var/lib/tor/my_onion_site

EXPOSE 10000

CMD service nginx start && \
    su -s /bin/bash debian-tor -c "tor" & \
    sleep 12 && \
    cat /var/lib/tor/my_onion_site/hostname && \
    tail -f /dev/null
