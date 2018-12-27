#!/bin/sh

cd /incoming

find . -mmin +15 -type f -print0 \
  | rsync  \
      --archive \
      --verbose \
      --files-from=- \
      --from0 \
      --remove-source-files \
      /incoming/ /data/

# needs GNU find for -empty
find . -type d -not -path ./.stfolder -empty -delete
