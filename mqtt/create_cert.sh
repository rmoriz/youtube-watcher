#!/bin/bash

openssl req \
  -new \
  -x509 \
  -nodes \
  -newkey \
  rsa:2048 \
  -keyout ca.key \
  -out ca.crt \
  -days 730 \
  -subj "/C=XY/ST=Internet/L=Internet/O=Internet/OU=Internet/CN=Internet"
