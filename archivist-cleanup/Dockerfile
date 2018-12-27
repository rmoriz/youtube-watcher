FROM alpine:latest

RUN apk add --no-cache rsync findutils

COPY cleanup.sh /usr/sbin/cleanup.sh
COPY crontab /etc/cron/crontab
RUN crontab /etc/cron/crontab && chmod 755 /usr/sbin/cleanup.sh

CMD ["crond", "-f"]
