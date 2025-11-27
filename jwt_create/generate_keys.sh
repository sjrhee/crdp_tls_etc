#!/bin/bash

# JWT 키 생성 스크립트
# 이 스크립트는 JWT 서명에 사용할 공개키/개인키 쌍을 생성합니다.

set -e

# 설정 변수 (필요시 수정)
ALGORITHM="ES256"        # 알고리즘: RS256, RS384, RS512, ES256, ES384, ES512, PS256, PS384, PS512
KEY_DIR="keys"           # 키 저장 디렉토리
KEY_PREFIX="jwt_key"     # 키 파일 이름 접두사

# 키 파일 경로
PRIVATE_KEY="$KEY_DIR/${KEY_PREFIX}_private.pem"
PUBLIC_KEY="$KEY_DIR/${KEY_PREFIX}_public.pem"

echo "=== JWT 키 생성 시작 ==="
echo "알고리즘: $ALGORITHM"

# keys 디렉토리 생성
mkdir -p "$KEY_DIR"

# 기존 파일 삭제
rm -f "$PRIVATE_KEY" "$PUBLIC_KEY"

# 알고리즘에 따라 키 생성
case $ALGORITHM in
  RS256|RS384|RS512|PS256|PS384|PS512)
    # RSA 키 생성
    echo "[1/2] RSA 개인키 생성..."
    openssl genrsa -out "$PRIVATE_KEY" 2048 2>/dev/null
    
    echo "[2/2] RSA 공개키 추출..."
    openssl rsa -in "$PRIVATE_KEY" -pubout -out "$PUBLIC_KEY" 2>/dev/null
    ;;
    
  ES256)
    # ECDSA P-256 키 생성
    echo "[1/2] ECDSA P-256 개인키 생성..."
    openssl ecparam -genkey -name prime256v1 -out "$PRIVATE_KEY" 2>/dev/null
    
    echo "[2/2] ECDSA 공개키 추출..."
    openssl ec -in "$PRIVATE_KEY" -pubout -out "$PUBLIC_KEY" 2>/dev/null
    ;;
    
  ES384)
    # ECDSA P-384 키 생성
    echo "[1/2] ECDSA P-384 개인키 생성..."
    openssl ecparam -genkey -name secp384r1 -out "$PRIVATE_KEY" 2>/dev/null
    
    echo "[2/2] ECDSA 공개키 추출..."
    openssl ec -in "$PRIVATE_KEY" -pubout -out "$PUBLIC_KEY" 2>/dev/null
    ;;
    
  ES512)
    # ECDSA P-521 키 생성
    echo "[1/2] ECDSA P-521 개인키 생성..."
    openssl ecparam -genkey -name secp521r1 -out "$PRIVATE_KEY" 2>/dev/null
    
    echo "[2/2] ECDSA 공개키 추출..."
    openssl ec -in "$PRIVATE_KEY" -pubout -out "$PUBLIC_KEY" 2>/dev/null
    ;;
    
  *)
    echo "오류: 지원하지 않는 알고리즘입니다: $ALGORITHM"
    echo "지원 알고리즘: RS256, RS384, RS512, ES256, ES384, ES512, PS256, PS384, PS512"
    exit 1
    ;;
esac

# 파일 권한 설정
chmod 600 "$PRIVATE_KEY"
chmod 644 "$PUBLIC_KEY"

echo ""
echo "=== 키 생성 완료 ==="
echo "개인키: $PRIVATE_KEY"
echo "공개키: $PUBLIC_KEY"
echo ""
echo "키 정보 확인:"
if [[ $ALGORITHM == ES* ]]; then
  echo "  openssl ec -in $PRIVATE_KEY -text -noout"
else
  echo "  openssl rsa -in $PRIVATE_KEY -text -noout"
fi
