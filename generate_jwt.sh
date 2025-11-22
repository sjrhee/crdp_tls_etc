#!/usr/bin/env bash
set -euo pipefail

# 사용법:
#   ./generate_jwt.sh <iss> <sub> [private_key_file]
#
# 예:
#   ./generate_jwt.sh "jwt-issuer" "username"
#   ./generate_jwt.sh "jwt-issuer" "username" jwt_signing_key.pem

ISS="${1:-jwt-issuer}"
SUB="${2:-username}"
PRIVATE_KEY="${3:-jwt_signing_key.pem}"

# Base64URL 인코딩 함수
b64url() {
  # stdin으로 들어온 데이터를 base64URL로 변환
  openssl base64 -e -A | tr '+/' '-_' | tr -d '='
}

# 1) Header 생성
HEADER='{"alg":"RS256","typ":"JWT"}'

# 2) Payload 생성 (iat/exp 포함)
NOW=$(date +%s)           # 현재 시각 (UNIX epoch)
# EXP 설정: 아래를 수정하여 만료 일자 지정
# 예: EXP=$(date -d "2025-12-31" +%s)  # 특정 날짜
# 예: EXP=$(date -d "+30 days" +%s)    # 30일 후
EXP=$(date -d "+1 day" +%s)             # 기본값: 1일 후

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

