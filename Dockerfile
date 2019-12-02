FROM php:7.3-fpm-alpine
MAINTAINER Simon Erhardt <hello@rootlogin.ch>

ARG NEXTCLOUD_GPG="2880 6A87 8AE4 23A2 8372  792E D758 99B9 A724 937A"
ARG NEXTCLOUD_VERSION=17.0.0
ARG UID=1501
ARG GID=1501

RUN set -ex \
  && apk update \
  && apk upgrade \
  && apk add \
  alpine-sdk \
  autoconf \
  bash \
  freetype \
  freetype-dev \
  gnupg \
  icu-dev \
  icu-libs \
  imagemagick \
  imagemagick-dev \
  libjpeg-turbo \
  libjpeg-turbo-dev \
  libldap \
  libmcrypt \
  libmcrypt-dev \
  libmemcached \
  libmemcached-dev \
  libpng \
  libpng-dev \
  libzip \
  libzip-dev \
  nginx \
  openldap-dev \
  openssl \
  pcre \
  pcre-dev \
  postgresql-dev \
  postgresql-libs \
  samba-client \
  sudo \
  supervisor \
  tar \
  tini \
  wget \
  redis \
  redis-openrc \

# PHP Extensions
# https://docs.nextcloud.com/server/9/admin_manual/installation/source_installation.html
  && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
  && docker-php-ext-configure ldap \
  && docker-php-ext-configure zip --with-libzip=/usr \
  && pecl install mcrypt-1.0.2 \
  && docker-php-ext-enable mcrypt \
  && docker-php-ext-install gd exif intl mbstring ldap mysqli opcache pcntl pdo_mysql pdo_pgsql pgsql zip \
  && pecl install APCu-5.1.16 \
  && pecl install imagick-3.4.3 \
  && pecl install memcached-3.1.3 \
  && pecl install redis-4.2.0 \
  && docker-php-ext-enable apcu imagick redis memcached \

# Remove dev packages
  && apk del \
    alpine-sdk \
    autoconf \
    freetype-dev \
    icu-dev \
    imagemagick-dev \
    libmcrypt-dev \
    libmemcached-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libzip-dev \
    openldap-dev \
    pcre-dev \
    postgresql-dev \
  && rm -rf /var/cache/apk/* \
  # Add user for nextcloud
  && addgroup -g ${GID} nextcloud \
  && adduser -u ${UID} -h /opt/nextcloud -H -G nextcloud -s /sbin/nologin -D nextcloud \
  && mkdir -p /opt/nextcloud \

# Download Nextcloud
  && cd /tmp \
  && NEXTCLOUD_TARBALL="nextcloud-${NEXTCLOUD_VERSION}.tar.bz2" \
  && wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL} \
  && wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.sha256 \
  && wget -q https://download.nextcloud.com/server/releases/${NEXTCLOUD_TARBALL}.asc \
  && wget -q https://nextcloud.com/nextcloud.asc \

# Verify checksum
  && echo "Verifying both integrity and authenticity of ${NEXTCLOUD_TARBALL}..." \
  && CHECKSUM_STATE=$(echo -n $(sha256sum -c ${NEXTCLOUD_TARBALL}.sha256) | tail -c 2) \
  && if [ "${CHECKSUM_STATE}" != "OK" ]; then echo "Warning! Checksum does not match!" && exit 1; fi \
  && gpg --import nextcloud.asc \
  && FINGERPRINT="$(LANG=C gpg --verify ${NEXTCLOUD_TARBALL}.asc ${NEXTCLOUD_TARBALL} 2>&1 | sed -n "s#Primary key fingerprint: \(.*\)#\1#p")" \
  && if [ -z "${FINGERPRINT}" ]; then echo "Warning! Invalid GPG signature!" && exit 1; fi \
  && if [ "${FINGERPRINT}" != "${NEXTCLOUD_GPG}" ]; then echo "Warning! Wrong GPG fingerprint!" && exit 1; fi \
  && echo "All seems good, now unpacking ${NEXTCLOUD_TARBALL}..." \

# Extract
  && tar xjf ${NEXTCLOUD_TARBALL} --strip-components=1 -C /opt/nextcloud \
# Remove nextcloud updater for safety
  && rm -rf /opt/nextcloud/updater \
  && rm -rf /tmp/* /root/.gnupg \
# Wipe excess directories
  && rm -rf /var/www/*

COPY root /

RUN chmod +x /usr/local/bin/run.sh /usr/local/bin/occ /etc/periodic/15min/nextcloud

RUN mkdir /data /config /apps2 && chown -R nextcloud:nextcloud /data /config /apps2

VOLUME /data /config /apps2

EXPOSE 80

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/usr/local/bin/run.sh"]
