#!/usr/bin/env bash
set -euo pipefail

# 사용법:
#   ./generate_jwt.sh <iss> <sub> [private_key_file] [kid]
#
# 예:
#   ./generate_jwt.sh "https://id.example.com" "alice"
#   ./generate_jwt.sh "https://id.example.com" "alice" jwt_signing_key.pem my-key-id-1

ISS="${1:-https://192.168.0.233:32182}"
SUB="${2:-user01}"
PRIVATE_KEY="${3:-jwt_signing_key.pem}"
KID="${4:-}"

# Base64URL 인코딩 함수
b64url() {
  # stdin으로 들어온 데이터를 base64URL로 변환
  openssl base64 -e -A | tr '+/' '-_' | tr -d '='
}

# 1) Header 생성
if [ -n "$KID" ]; then
  HEADER='{"alg":"RS256","typ":"JWT","kid":"'"$KID"'"}'
else
  HEADER='{"alg":"RS256","typ":"JWT"}'
fi

# 2) Payload 생성 (iat/exp 포함)
NOW=$(date +%s)           # 현재 시각 (UNIX epoch)
EXP=$((NOW + 3600))       # 1시간 후 (3600초 후)

PAYLOAD='{"iss":"'"$ISS"'","sub":"'"$SUB"'","iat":'"$NOW"',"exp":'"$EXP"'}'

# 3) Base64URL(Header, Payload)
HEADER_B64=$(printf '%s' "$HEADER"   | b64url)
PAYLOAD_B64=$(printf '%s' "$PAYLOAD" | b64url)

# 4) Signing Input 생성
SIGNING_INPUT="${HEADER_B64}.${PAYLOAD_B64}"

# 5) Private Key로 서명 (RS256: SHA256 + RSA)
SIGNATURE=$(printf '%s' "$SIGNING_INPUT" \
  | openssl dgst -sha256 -sign "$PRIVATE_KEY" -binary \
  | b64url)

# 6) 최종 JWT
JWT="${SIGNING_INPUT}.${SIGNATURE}"

echo "$JWT"

