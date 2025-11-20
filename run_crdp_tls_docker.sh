set -e
CERT_VALUE=$(cat Certificate.pem)
KEY_VALUE=$(cat key.pem)
TRUSTED_CA=$(cat ca.pem)

docker run -d -e KEY_MANAGER_HOST=192.168.0.230 -e REGISTRATION_TOKEN=U3Sca0xJYr1QHXFWJGBA15uXGmMNnDdV0syeCOXt6LjXa8PYtbxyuyWmuL9P1IrA \
  --restart unless-stopped -p 32182:8090 -p 32180:8080 -e SERVER_MODE=tls-cert-opt \
  -e CERT_VALUE="$CERT_VALUE" -e KEY_VALUE="$KEY_VALUE" -e TRUSTED_CA="$TRUSTED_CA" \
  thalesciphertrust/ciphertrust-restful-data-protection

#
#docker run -e KEY_MANAGER_HOST=<IP address or host name> -e REGISTRATION_TOKEN=<registration token> -p <host port>:<CRDP_port> \
#-e SERVER_MODE=tls-cert-opt -e CERT_VALUE="<certificate value>" -e KEY_VALUE="<key value>" <crdp image name>
