FROM syncthing/syncthing:latest

RUN mkdir -p /syncthing/config
COPY config /syncthing/config

ENTRYPOINT \
  chown -R "${PUID}:${PGID}" /syncthing \
  && chown -R "${PUID}:${PGID}" /data \
  && su-exec "${PUID}:${PGID}" \
     env HOME=/syncthing \
     /bin/syncthing \
       -home /syncthing/config \
       -gui-address 0.0.0.0:8384
