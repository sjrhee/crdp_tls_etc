#!/bin/bash

# PEM 파일 생성 스크립트
# 이 스크립트는 run_crdp_tls_docker.sh에서 사용할 TLS 인증서 파일들을 생성합니다.

set -e

# 인증서 설정 (필요시 아래 값을 수정하세요)
DAYS_VALID=3650
KEY_SIZE=2048
COUNTRY="KR"
STATE="Seoul"
LOCALITY="Seoul"
ORGANIZATION="LocalTest"
ORGANIZATIONAL_UNIT="IT"
COMMON_NAME="localhost"

# keys 폴더 생성
KEYS_DIR="keys"
mkdir -p "$KEYS_DIR"

echo "=== TLS 인증서 생성 시작 ==="

# 기존 파일 삭제
rm -f "$KEYS_DIR"/*.pem "$KEYS_DIR"/*.csr "$KEYS_DIR"/*.cnf "$KEYS_DIR"/*.srl

# 1. CA 개인키 생성
echo "[1/5] CA 개인키 생성..."
openssl genrsa -out "$KEYS_DIR/ca-key.pem" $KEY_SIZE 2>/dev/null

# 2. CA 인증서 생성
echo "[2/5] CA 인증서 생성..."
openssl req -new -x509 -days $DAYS_VALID -key "$KEYS_DIR/ca-key.pem" -out "$KEYS_DIR/ca.pem" \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT CA/CN=$COMMON_NAME CA" 2>/dev/null

# 3. 서버 개인키 생성
echo "[3/5] 서버 개인키 생성..."
openssl genrsa -out "$KEYS_DIR/key.pem" $KEY_SIZE 2>/dev/null

# 4. 서버 CSR 생성
echo "[4/5] 서버 CSR 생성..."
openssl req -new -key "$KEYS_DIR/key.pem" -out "$KEYS_DIR/cert.csr" \
    -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$COMMON_NAME" 2>/dev/null

# 5. 서버 인증서 서명
echo "[5/5] 서버 인증서 서명..."
cat > "$KEYS_DIR/san.cnf" << EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = $COUNTRY
ST = $STATE
L = $LOCALITY
O = $ORGANIZATION
OU = $ORGANIZATIONAL_UNIT
CN = $COMMON_NAME

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $COMMON_NAME
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

openssl x509 -req -in "$KEYS_DIR/cert.csr" -CA "$KEYS_DIR/ca.pem" -CAkey "$KEYS_DIR/ca-key.pem" -CAcreateserial \
    -out "$KEYS_DIR/cert.pem" -days $DAYS_VALID -extensions v3_req -extfile "$KEYS_DIR/san.cnf" 2>/dev/null

# 임시 파일 정리
rm -f "$KEYS_DIR/cert.csr" "$KEYS_DIR/san.cnf" "$KEYS_DIR/ca.srl"

# 파일 권한 설정
chmod 600 "$KEYS_DIR/ca-key.pem" "$KEYS_DIR/key.pem"
chmod 644 "$KEYS_DIR/ca.pem" "$KEYS_DIR/cert.pem"

echo ""
echo "=== 인증서 생성 완료 ==="
echo "생성된 파일: $KEYS_DIR/ca.pem, $KEYS_DIR/ca-key.pem, $KEYS_DIR/cert.pem, $KEYS_DIR/key.pem"
