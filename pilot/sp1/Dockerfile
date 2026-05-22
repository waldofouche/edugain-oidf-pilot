FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends apache2 libapache2-mod-auth-mellon ca-certificates bash \
    && a2enmod auth_mellon cgid headers \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 80

CMD ["apache2ctl", "-D", "FOREGROUND"]

