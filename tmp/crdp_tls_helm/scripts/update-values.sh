#!/bin/bash

# Base64 인코딩 및 values.yaml 업데이트 스크립트

cd "$(dirname "$0")/.."

echo "=== Base64 인코딩 시작 ==="

CERT=$(cat certs/cert.pem | base64 -w 0)
KEY=$(cat certs/prikey.pem | base64 -w 0)

echo "✓ 인증서 인코딩 완료"

cat > values.yaml << 'ENDOFFILE'
label: crdp-tls

deployment:
  name: crdp-tls-deployment
  crdpContainername: crdp-tls-container
  crdpimage: thalesciphertrust/ciphertrust-restful-data-protection:latest
  replicas: 2

env:
  serverMode: tls-cert-opt
  kms: 192.168.0.230
  regToken: NpxeOKdvzMXq2jxURZUPbILDtd0RGfPdWiG7Y6JsVTY4ZdiEIlnyMdWIncEZJilV

service:
  name: crdp-tls-service
  type: NodePort
  nodePort: 32382
  port: 8090
  probesPort: 8080
  nodePortForProbes: 32380

configuration:
ENDOFFILE

echo "  servercrt: $CERT" >> values.yaml
echo "  serverkey: $KEY" >> values.yaml

echo "✓ values.yaml 업데이트 완료"
echo ""
echo "=== 파일 확인 ==="
ls -lah values.yaml
