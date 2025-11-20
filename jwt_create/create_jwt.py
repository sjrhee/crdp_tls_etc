#!/usr/bin/env python3

"""
Regular JWT 생성 스크립트
Thales CRDP JWT 형식을 따릅니다.
OpenSSL 명령어를 사용하여 cryptography 라이브러리 없이 구현
"""

import os
import sys
import json
import base64
import time
import subprocess
from pathlib import Path
from datetime import datetime, timedelta

# ============================================================================
# 설정 로드
# ============================================================================

def load_config(config_file: str = "config.yaml") -> dict:
    """YAML 설정 파일 로드"""
    if not os.path.exists(config_file):
        print(f"❌ 오류: {config_file} 파일을 찾을 수 없습니다.")
        sys.exit(1)
    
    try:
        with open(config_file, 'r', encoding='utf-8') as f:
            config = parse_yaml_simple(f.read())
        return config
    except Exception as e:
        print(f"❌ 설정 파일 로드 실패: {e}")
        sys.exit(1)

def parse_yaml_simple(content: str) -> dict:
    """간단한 YAML 파서 (PyYAML 없을 때 사용)"""
    config = {}
    for line in content.split('\n'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        
        if ':' in line:
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            
            # 타입 변환
            if value.lower() == 'true':
                config[key] = True
            elif value.lower() == 'false':
                config[key] = False
            elif value.isdigit():
                config[key] = int(value)
            else:
                config[key] = value
    
    return config

# 설정 로드
CONFIG = load_config("config.yaml")

# 설정 변수 추출
ALGORITHM = CONFIG.get("algorithm", "ES256")
ISSUER = CONFIG.get("issuer", "CRDP03")
USER_ID = CONFIG.get("user_id", "user01")
EXPIRY_DAYS = CONFIG.get("expiry_days", 30)
KEY_DIR = CONFIG.get("key_dir", "./keys")
KEY_NAME_PREFIX = CONFIG.get("key_name_prefix", "jwt_key")
USE_EXISTING_KEYS = CONFIG.get("use_existing_keys", False)

# ============================================================================
# 유틸리티 함수
# ============================================================================

def base64url_encode(data: bytes) -> str:
    """Base64URL 인코딩 (패딩 없음)"""
    return base64.urlsafe_b64encode(data).rstrip(b'=').decode('utf-8')

def base64url_decode(data: str) -> bytes:
    """Base64URL 디코딩 (패딩 추가)"""
    padding = 4 - (len(data) % 4)
    data += '=' * padding
    return base64.urlsafe_b64decode(data)

def run_command(cmd: list) -> bytes:
    """명령어 실행 및 결과 반환"""
    try:
        result = subprocess.run(cmd, capture_output=True, check=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"❌ 명령어 실행 실패: {' '.join(cmd)}")
        print(f"   오류: {e.stderr.decode('utf-8', errors='ignore')}")
        sys.exit(1)

def check_openssl():
    """OpenSSL 명령어 존재 여부 확인"""
    try:
        run_command(["openssl", "version"])
    except FileNotFoundError:
        print("❌ 오류: openssl 명령어를 찾을 수 없습니다.")
        sys.exit(1)

def get_key_size(algorithm: str) -> int:
    """알고리즘에 따른 RSA 키 크기 반환"""
    if algorithm in ["RS256", "PS256"]:
        return 2048
    elif algorithm in ["RS384", "PS384"]:
        return 3072
    elif algorithm in ["RS512", "PS512"]:
        return 4096
    return 2048

def get_openssl_curve(algorithm: str) -> str:
    """알고리즘에 따른 OpenSSL EC 곡선명 반환"""
    if algorithm == "ES256":
        return "prime256v1"
    elif algorithm == "ES384":
        return "secp384r1"
    elif algorithm == "ES512":
        return "secp521r1"
    return "prime256v1"

def get_openssl_hash_option(algorithm: str) -> str:
    """알고리즘에 따른 OpenSSL 해시 옵션 반환"""
    if algorithm in ["RS256", "ES256", "PS256"]:
        return "-sha256"
    elif algorithm in ["RS384", "ES384", "PS384"]:
        return "-sha384"
    elif algorithm in ["RS512", "ES512", "PS512"]:
        return "-sha512"
    return "-sha256"

# ============================================================================
# 키 생성 함수
# ============================================================================

def generate_rsa_keys(key_size: int):
    """RSA 키 쌍 생성"""
    print(f"   RSA 키 생성 중 (크기: {key_size} bits)...")
    run_command(["openssl", "genrsa", "-out", f"{KEY_DIR}/{KEY_NAME_PREFIX}_private.pem", str(key_size)])
    run_command(["openssl", "rsa", "-in", f"{KEY_DIR}/{KEY_NAME_PREFIX}_private.pem", 
                 "-pubout", "-out", f"{KEY_DIR}/{KEY_NAME_PREFIX}_public.pem"])

def generate_ec_keys(algorithm: str):
    """EC 키 쌍 생성"""
    curve = get_openssl_curve(algorithm)
    print(f"   ECDSA 키 생성 중 (곡선: {curve})...")
    run_command(["openssl", "ecparam", "-name", curve, "-genkey", 
                 "-out", f"{KEY_DIR}/{KEY_NAME_PREFIX}_private.pem"])
    run_command(["openssl", "ec", "-in", f"{KEY_DIR}/{KEY_NAME_PREFIX}_private.pem",
                 "-pubout", "-out", f"{KEY_DIR}/{KEY_NAME_PREFIX}_public.pem"])

def generate_pss_keys(key_size: int):
    """PSS (RSA-PSS) 키 쌍 생성 (일반 RSA와 동일하게 생성)"""
    print(f"   RSA-PSS 키 생성 중 (크기: {key_size} bits)...")
    run_command(["openssl", "genrsa", "-out", f"{KEY_DIR}/{KEY_NAME_PREFIX}_private.pem", str(key_size)])
    run_command(["openssl", "rsa", "-in", f"{KEY_DIR}/{KEY_NAME_PREFIX}_private.pem",
                 "-pubout", "-out", f"{KEY_DIR}/{KEY_NAME_PREFIX}_public.pem"])

def save_keys_info():
    """키 저장 정보 표시"""
    print(f"✅ 키 생성 완료:")
    print(f"   Private: {KEY_DIR}/{KEY_NAME_PREFIX}_private.pem")
    print(f"   Public:  {KEY_DIR}/{KEY_NAME_PREFIX}_public.pem")

# ============================================================================
# JWT 생성 함수
# ============================================================================

def der_to_jwt_signature(der_bytes: bytes, algorithm: str) -> bytes:
    """ECDSA DER 형식 서명을 JWT 형식(r,s)으로 변환"""
    
    if len(der_bytes) < 8:
        raise ValueError("Invalid DER signature format")
    
    # DER 파싱: 0x30 [length] 0x02 [r_length] [r_bytes] 0x02 [s_length] [s_bytes]
    if der_bytes[0] != 0x30:
        raise ValueError("Invalid DER format (expected 0x30)")
    
    idx = 2  # Skip 0x30 and length
    
    # r 값 파싱
    if der_bytes[idx] != 0x02:
        raise ValueError("Invalid DER format (expected 0x02 for r)")
    idx += 1
    r_length = der_bytes[idx]
    idx += 1
    r_bytes = der_bytes[idx:idx + r_length]
    idx += r_length
    
    # s 값 파싱
    if der_bytes[idx] != 0x02:
        raise ValueError("Invalid DER format (expected 0x02 for s)")
    idx += 1
    s_length = der_bytes[idx]
    idx += 1
    s_bytes = der_bytes[idx:idx + s_length]
    
    # 알고리즘에 따른 출력 크기 결정
    if algorithm == "ES256":
        output_size = 32  # 256 bits = 32 bytes
    elif algorithm == "ES384":
        output_size = 48  # 384 bits = 48 bytes
    elif algorithm == "ES512":
        output_size = 66  # 521 bits = 66 bytes
    else:
        raise ValueError(f"Unknown ECDSA algorithm: {algorithm}")
    
    # r, s를 고정 크기로 정렬 (앞에 0x00 추가)
    r_padded = r_bytes.rjust(output_size, b'\x00')
    s_padded = s_bytes.rjust(output_size, b'\x00')
    
    return r_padded + s_padded

def create_jwt(algorithm: str, issuer: str, user_id: str, expiry_days: int) -> str:
    """JWT 토큰 생성"""
    
    # 헤더 생성
    header = {
        "alg": algorithm,
        "typ": "JWT"
    }
    header_json = json.dumps(header, separators=(',', ':'))
    header_b64 = base64url_encode(header_json.encode('utf-8'))
    
    # 페이로드 생성
    now = int(time.time())
    expiry_timestamp = now + (expiry_days * 86400)  # expiry_days를 초로 변환
    
    payload = {
        "exp": expiry_timestamp,
        "iss": issuer,
        "sub": user_id
    }
    payload_json = json.dumps(payload, separators=(',', ':'))
    payload_b64 = base64url_encode(payload_json.encode('utf-8'))
    
    # 서명 입력값 (header.payload)
    signing_input = f"{header_b64}.{payload_b64}"
    
    # 서명 생성
    hash_option = get_openssl_hash_option(algorithm)
    key_file = f"{KEY_DIR}/{KEY_NAME_PREFIX}_private.pem"
    
    if algorithm.startswith("RS"):
        # RSA 서명 (PKCS1v15)
        cmd = ["openssl", "dgst", hash_option, "-sign", key_file]
        result = subprocess.run(cmd, input=signing_input.encode('utf-8'), 
                              capture_output=True, check=True)
        signature_bytes = result.stdout
    elif algorithm.startswith("PS"):
        # RSA-PSS 서명
        cmd = ["openssl", "dgst", hash_option, "-sigopt", "rsa_padding_mode:pss", "-sign", key_file]
        result = subprocess.run(cmd, input=signing_input.encode('utf-8'),
                              capture_output=True, check=True)
        signature_bytes = result.stdout
    elif algorithm.startswith("ES"):
        # ECDSA 서명 (DER → JWT 형식)
        cmd = ["openssl", "dgst", hash_option, "-sign", key_file]
        result = subprocess.run(cmd, input=signing_input.encode('utf-8'),
                              capture_output=True, check=True)
        der_signature = result.stdout
        signature_bytes = der_to_jwt_signature(der_signature, algorithm)
    else:
        raise ValueError(f"지원하지 않는 알고리즘: {algorithm}")
    
    # 서명을 Base64URL 인코딩
    signature_b64 = base64url_encode(signature_bytes)
    
    # JWT 토큰 생성
    jwt_token = f"{header_b64}.{payload_b64}.{signature_b64}"
    
    return jwt_token

# ============================================================================
# 메인 함수
# ============================================================================

def main():
    """메인 함수"""
    
    print("=" * 80)
    print("Regular JWT 생성 (Python)")
    print("=" * 80)
    
    # OpenSSL 확인
    check_openssl()
    
    # 설정 표시
    print(f"\n📋 설정:")
    print(f"   알고리즘: {ALGORITHM}")
    print(f"   발급자: {ISSUER}")
    print(f"   사용자 ID: {USER_ID}")
    print(f"   유효기간: {EXPIRY_DAYS}일")
    print(f"   키 디렉토리: {KEY_DIR}")
    
    # 키 생성 또는 로드
    Path(KEY_DIR).mkdir(parents=True, exist_ok=True)
    key_path_private = f"{KEY_DIR}/{KEY_NAME_PREFIX}_private.pem"
    
    if not USE_EXISTING_KEYS or not os.path.exists(key_path_private):
        print(f"\n🔑 키 생성 중...")
        
        try:
            if ALGORITHM.startswith("RS"):
                # RSA 키 생성
                key_size = get_key_size(ALGORITHM)
                generate_rsa_keys(key_size)
            elif ALGORITHM.startswith("PS"):
                # PSS 키 생성
                key_size = get_key_size(ALGORITHM)
                generate_pss_keys(key_size)
            elif ALGORITHM.startswith("ES"):
                # ECDSA 키 생성
                generate_ec_keys(ALGORITHM)
            else:
                print(f"❌ 지원하지 않는 알고리즘: {ALGORITHM}")
                sys.exit(1)
            
            save_keys_info()
        except Exception as e:
            print(f"❌ 키 생성 실패: {e}")
            sys.exit(1)
    else:
        print(f"\n✅ 기존 키 사용")
    
    # JWT 생성
    print(f"\n🔨 JWT 생성 중...")
    try:
        jwt_token = create_jwt(
            ALGORITHM,
            ISSUER,
            USER_ID,
            EXPIRY_DAYS
        )
        print(f"✅ JWT 생성 완료\n")
    except Exception as e:
        print(f"❌ JWT 생성 실패: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
    
    # 토큰 저장
    output_file = "keys/jwt_token.txt"
    Path("keys").mkdir(parents=True, exist_ok=True)
    with open(output_file, "w") as f:
        f.write(jwt_token)
    print(f"💾 토큰 저장: {output_file}")
    
    # 토큰 표시
    print(f"\n📌 JWT 토큰:")
    print(jwt_token)
    
    # 토큰 디코드 정보 표시
    print(f"\n📖 토큰 정보:")
    try:
        parts = jwt_token.split(".")
        header = json.loads(base64url_decode(parts[0]))
        payload = json.loads(base64url_decode(parts[1]))
        
        print(f"   헤더: {json.dumps(header)}")
        print(f"   페이로드: {json.dumps(payload)}")
        
        # 만료 시간 표시
        exp_time = datetime.fromtimestamp(payload['exp'])
        print(f"   만료: {exp_time.strftime('%Y-%m-%d %H:%M:%S')} ({payload['exp']})")
    except Exception as e:
        print(f"   ⚠️  토큰 정보 표시 실패: {e}")

if __name__ == "__main__":
    main()
