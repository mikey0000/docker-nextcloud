#!/bin/bash

# SIGTERM-handler
term_handler() {
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
  fi
  exit 143; # 128 + 15 -- SIGTERM
}

# Bootstrap application
echo "Preparing environment... (This will take some time...)"

if [ ! -d /data/config ]; then
  mkdir /data/config
fi

cp -f /opt/nextcloud/config/config.sample.php /data/config/
cp -f /opt/nextcloud/config/docker.config.php /data/config/


# Put the configuration and apps into volumes
ln -sf /config/config.php /opt/nextcloud/config/config.php &>/dev/null
ln -sf /apps2 /opt/nextcloud &>/dev/null

# Create folder for php sessions if not exists
if [ ! -d /data/session ]; then
  mkdir -p /data/session;
fi

echo "Updating permissions..."
for dir in /nextcloud /data /config /apps2 /etc/nginx /etc/php7 /var/log /var/lib/nginx /tmp /etc/s6.d; do
  if $(find $dir ! -user $UID -o ! -group $GID|egrep '.' -q); then
    echo "Updating permissions in $dir..."
    chown -R $UID:$GID $dir
  else
    echo "Permissions in $dir are correct."
  fi
done
echo "Done updating permissions."


if [ ! -f /config/config.php ]; then
    # New installation, run the setup
    /usr/local/bin/setup.sh
else
    occ upgrade
    if [ \( $? -ne 0 \) -a \( $? -ne 3 \) ]; then
        echo "Trying ownCloud upgrade again to work around ownCloud upgrade bug..."
        occ upgrade
        if [ \( $? -ne 0 \) -a \( $? -ne 3 \) ]; then exit 1; fi
        occ maintenance:mode --off
        echo "...which seemed to work."
    fi
fi



# run application
echo "Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
