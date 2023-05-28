#!/bin/sh

conf_path=/aria2/conf
conf_copy_path=/aria2/conf-copy
data_path=/aria2/data

# If config does not exist - use default
if [ ! -f $conf_path/aria2.conf ]; then
    cp $conf_copy_path/aria2.conf $conf_path/aria2.conf
fi

userid="$(id -u)" # 65534 - nobody, 0 - root
groupid="$(id -g)"

if [[ -n "$PUID" && -n "$PGID" ]]; then
    echo "Running as user $PUID:$PGID"
    userid=$PUID
    groupid=$PGID
fi

# chown -R "$userid":"$groupid" $conf_path
# chown -R "$userid":"$groupid" $data_path

caddy start -config /usr/local/caddy/Caddyfile -adapter=caddyfile
cat $conf_path/aria2.conf
aria2c "$@"
