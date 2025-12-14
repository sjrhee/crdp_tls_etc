set -e

# 설정 변수
KEY_MANAGER_HOST="192.168.0.101"
KEY_MANAGER_PORT="10024"
REGISTRATION_TOKEN="U22sK5xJoyEDRuLpCijA7sq8BAMUVXvVlMsUBWoaWa1zEO1n4OWStqnqtPHdDGZz"
HOST_PORT_CRDP=32182
HOST_PORT_HEALTHZ=32180

# PEM 파일 읽기
CERT_VALUE=$(cat keys/cert.pem)
KEY_VALUE=$(cat keys/key.pem)
TRUSTED_CA=$(cat keys/ca.pem)

docker run -d -e KEY_MANAGER_HOST=$KEY_MANAGER_HOST -e KEY_MANAGER_PORT=$KEY_MANAGER_PORT -e REGISTRATION_TOKEN=$REGISTRATION_TOKEN \
  -p $HOST_PORT_CRDP:8090 -p $HOST_PORT_HEALTHZ:8080 -e SERVER_MODE=tls-cert-opt \
  -e CERT_VALUE="$CERT_VALUE" -e KEY_VALUE="$KEY_VALUE" -e TRUSTED_CA="$TRUSTED_CA" \
  thalesciphertrust/ciphertrust-restful-data-protection

#
#docker run -e KEY_MANAGER_HOST=<IP address or host name> -e REGISTRATION_TOKEN=<registration token> -p <host port>:<CRDP_port> \
#-e SERVER_MODE=tls-cert-opt -e CERT_VALUE="<certificate value>" -e KEY_VALUE="<key value>" <crdp image name>
