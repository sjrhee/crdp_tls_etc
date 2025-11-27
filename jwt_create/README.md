# JWT 키 생성 가이드

이 디렉토리는 JWT(JSON Web Token) 생성 및 관리를 위한 도구를 포함합니다.

## 파일 구성

- `generate_keys.sh` - JWT 서명용 공개키/개인키 쌍 생성 스크립트
- `generate_jwt.py` - Python을 이용한 JWT 생성 도구 (OpenSSL 사용, 추가 라이브러리 불필요)
- `run.sh` - JWT 생성 간편 실행 스크립트
- `config.yaml` - JWT 생성 설정 파일
- `keys/` - 생성된 키 파일 저장 디렉토리

## 사용 방법

### 1단계: 키 생성

먼저 JWT 서명에 사용할 공개키/개인키 쌍을 생성합니다.

```bash
./generate_keys.sh
```

스크립트는 `config.yaml`에 설정된 알고리즘에 따라 자동으로 키를 생성합니다.

#### 지원 알고리즘

- **RSA**: RS256, RS384, RS512, PS256, PS384, PS512
- **ECDSA**: ES256, ES384, ES512

#### 알고리즘 변경

`generate_keys.sh` 파일 상단의 `ALGORITHM` 변수를 수정하거나, `config.yaml`의 `algorithm` 값을 변경하세요.

```bash
# generate_keys.sh
ALGORITHM="ES256"  # 기본값: ES256
```

생성되는 파일:
- `keys/jwt_key_private.pem` - 개인키 (서명용, 안전하게 보관)
- `keys/jwt_key_public.pem` - 공개키 (검증용)

### 2단계: JWT 토큰 생성

간편 실행 스크립트를 사용하거나 Python 스크립트를 직접 실행합니다.

**방법 1: 간편 실행 (권장)**
```bash
./run.sh
```

**방법 2: 직접 실행**
```bash
python3 generate_jwt.py
```

`config.yaml` 파일의 설정을 사용하여 JWT를 생성합니다.

## 설정 파일 (config.yaml)

```yaml
# JWT 알고리즘
algorithm: ES256

# 발급자 (Issuer)
issuer: CRDP03

# 사용자 ID (Subject)
user_id: user01

# 토큰 유효기간 (일)
expiry_days: 30

# 키 저장 디렉토리
key_dir: ./keys

# 키 파일 이름 접두사
key_name_prefix: jwt_key

# 기존 키 사용 여부
use_existing_keys: false
```

## 키 정보 확인

### ECDSA 키 확인

```bash
# 개인키 정보
openssl ec -in keys/jwt_key_private.pem -text -noout

# 공개키 정보
openssl ec -pubin -in keys/jwt_key_public.pem -text -noout
```

### RSA 키 확인

```bash
# 개인키 정보
openssl rsa -in keys/jwt_key_private.pem -text -noout

# 공개키 정보
openssl rsa -pubin -in keys/jwt_key_public.pem -text -noout
```

## 보안 주의사항

⚠️ **중요**: 개인키는 절대 외부에 공유하지 마세요!

- `jwt_key_private.pem`은 JWT 서명에 사용되므로 안전하게 보관해야 합니다
- Git 저장소에 커밋하지 마세요 (`.gitignore`에 추가 권장)
- 적절한 파일 권한 설정 (개인키: 600, 공개키: 644)

## 알고리즘별 특징

### RSA (RS256, RS384, RS512)
- 가장 널리 사용되는 알고리즘
- 키 크기: 2048 비트 이상 권장
- 서명 크기가 큼

### ECDSA (ES256, ES384, ES512)
- RSA보다 작은 키 크기로 동일한 보안 수준 제공
- 서명 크기가 작음
- ES256: P-256 곡선 (권장)
- ES384: P-384 곡선
- ES512: P-521 곡선

### PSS (PS256, PS384, PS512)
- RSA-PSS 패딩 방식
- RSA보다 향상된 보안성

## 문제 해결

### "openssl: command not found" 오류

OpenSSL을 설치하세요:

```bash
# Ubuntu/Debian
sudo apt-get install openssl

# Red Hat/CentOS/Rocky Linux
sudo yum install openssl
```

### 키 생성 실패

1. OpenSSL 버전 확인:
   ```bash
   openssl version
   ```

2. 디렉토리 권한 확인:
   ```bash
   ls -la keys/
   ```

## 참고 자료

- [JWT 공식 사이트](https://jwt.io/)
- [RFC 7519 - JSON Web Token](https://tools.ietf.org/html/rfc7519)
- [OpenSSL 문서](https://www.openssl.org/docs/)
