FROM eclipse-mosquitto

ADD mosquitto.conf /mosquitto/config/mosquitto.conf

# create with mosquitto_passwd
ADD password_file /etc/mosquitto/password_file

# create with create_cert.sh
ADD ca.crt /var/lib/mosquitto/ca.crt
ADD ca.key /var/lib/mosquitto/ca.key
