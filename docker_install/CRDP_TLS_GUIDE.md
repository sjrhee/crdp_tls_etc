# CRDP TLS Docker 실행 가이드

이 가이드는 Thales CipherTrust Restful Data Protection (CRDP)을 TLS 모드로 Docker에서 실행하는 방법을 안내합니다.

## 파일 구성

- `generate_pem_files.sh` - TLS 인증서 및 키 파일 생성 스크립트
- `run_crdp_tls_docker.sh` - CRDP Docker 컨테이너 실행 스크립트

## 사전 요구사항

1. Docker가 설치되어 있어야 합니다
   - Ubuntu: [ubuntu_docker_install.md](ubuntu_docker_install.md) 참조
   - Red Hat: [redhat_docker_install.md](redhat_docker_install.md) 참조

2. OpenSSL이 설치되어 있어야 합니다
   ```bash
   # Ubuntu/Debian
   sudo apt-get install openssl
   
   # Red Hat/CentOS/Rocky Linux
   sudo yum install openssl
   ```

3. CipherTrust Manager 정보
   - Key Manager Host IP 주소
   - Registration Token

## 실행 단계

### 1단계: TLS 인증서 생성

먼저 `generate_pem_files.sh` 스크립트를 실행하여 필요한 PEM 파일들을 생성합니다.

```bash
cd /home/ubuntu/Work/crdp_tls_etc/docker_install
./generate_pem_files.sh
```

스크립트 실행 시 다음 정보를 입력합니다:
- **Common Name (CN)**: 서버의 호스트명 또는 도메인 (예: `crdp.example.com` 또는 `localhost`)
- **Organization (O)**: 조직명 (예: `MyCompany`)
- **Country (C)**: 국가 코드 (예: `KR`)
- **유효 기간**: 인증서 유효 일수 (기본값: 365일)

생성되는 파일:
- `cert.pem` - 서버 인증서
- `key.pem` - 서버 개인키
- `ca.pem` - CA 인증서 (신뢰할 수 있는 CA)
- `ca-key.pem` - CA 개인키 (안전하게 보관)

### 2단계: run_crdp_tls_docker.sh 수정

`run_crdp_tls_docker.sh` 파일을 열어 다음 환경 변수를 수정합니다:

```bash
# KEY_MANAGER_HOST를 실제 CipherTrust Manager IP로 변경
-e KEY_MANAGER_HOST=192.168.0.230

# REGISTRATION_TOKEN을 실제 토큰으로 변경
-e REGISTRATION_TOKEN=U3Sca0xJYr1QHXFWJGBA15uXGmMNnDdV0syeCOXt6LjXa8PYtbxyuyWmuL9P1IrA
```

필요한 경우 포트도 변경할 수 있습니다:
```bash
# 기본값: 호스트 32182 -> 컨테이너 8090 (HTTPS)
#         호스트 32180 -> 컨테이너 8080 (HTTP)
-p 32182:8090 -p 32180:8080
```

### 3단계: CRDP Docker 컨테이너 실행

```bash
./run_crdp_tls_docker.sh
```

### 4단계: 컨테이너 상태 확인

```bash
# 실행 중인 컨테이너 확인
docker ps

# 컨테이너 로그 확인
docker logs <container_id>
```

## 환경 변수 설명

| 환경 변수 | 설명 | 필수 여부 |
|----------|------|----------|
| `KEY_MANAGER_HOST` | CipherTrust Manager의 IP 주소 또는 호스트명 | 필수 |
| `REGISTRATION_TOKEN` | CipherTrust Manager에서 발급받은 등록 토큰 | 필수(선택) |
| `SERVER_MODE` | 서버 모드 (`tls-cert-opt`: TLS 인증서 사용) | 필수 |
| `CERT_VALUE` | 서버 인증서 내용 (cert.pem) | TLS 모드 시 필수 |
| `KEY_VALUE` | 서버 개인키 내용 (key.pem) | TLS 모드 시 필수 |
| `TRUSTED_CA` | 신뢰할 수 있는 CA 인증서 (ca.pem) | 선택 |

## 포트 정보

- **8090 (HTTPS)**: TLS 암호화된 CRDP API 엔드포인트
- **8080 (HTTP)**: HTTP CRDP API 엔드포인트 (선택사항)

## 인증서 정보 확인

생성된 인증서의 정보를 확인하려면:

```bash
# CA 인증서 확인
openssl x509 -in ca.pem -text -noout

# 서버 인증서 확인
openssl x509 -in cert.pem -text -noout

# 인증서 유효 기간 확인
openssl x509 -in cert.pem -noout -dates
```

## 문제 해결

### 컨테이너가 시작되지 않는 경우

1. Docker 로그 확인:
   ```bash
   docker logs <container_id>
   ```

2. PEM 파일이 올바르게 생성되었는지 확인:
   ```bash
   ls -la *.pem
   ```

3. 환경 변수가 올바르게 설정되었는지 확인:
   ```bash
   docker inspect <container_id>
   ```

### 인증서 오류가 발생하는 경우

1. 인증서 형식 확인:
   ```bash
   openssl x509 -in cert.pem -text -noout
   ```

2. 개인키와 인증서가 일치하는지 확인:
   ```bash
   openssl x509 -noout -modulus -in cert.pem | openssl md5
   openssl rsa -noout -modulus -in key.pem | openssl md5
   # 두 해시값이 동일해야 합니다
   ```

### 연결 오류가 발생하는 경우

1. 방화벽 설정 확인:
   ```bash
   # Ubuntu
   sudo ufw status
   sudo ufw allow 32182/tcp
   sudo ufw allow 32180/tcp
   
   # Red Hat/CentOS
   sudo firewall-cmd --list-all
   sudo firewall-cmd --permanent --add-port=32182/tcp
   sudo firewall-cmd --permanent --add-port=32180/tcp
   sudo firewall-cmd --reload
   ```

2. 포트가 이미 사용 중인지 확인:
   ```bash
   sudo netstat -tlnp | grep -E '32182|32180'
   ```

## 컨테이너 관리

### 컨테이너 중지

```bash
docker stop <container_id>
```

### 컨테이너 재시작

```bash
docker restart <container_id>
```

### 컨테이너 삭제

```bash
docker rm -f <container_id>
```

### 이미지 업데이트

```bash
# 최신 이미지 다운로드
docker pull thalesciphertrust/ciphertrust-restful-data-protection

# 기존 컨테이너 중지 및 삭제
docker stop <container_id>
docker rm <container_id>

# 새 컨테이너 실행
./run_crdp_tls_docker.sh
```

## 보안 권장사항

1. **개인키 보호**: `key.pem`과 `ca-key.pem` 파일은 안전하게 보관하고 권한을 제한하세요
   ```bash
   chmod 600 key.pem ca-key.pem
   ```

2. **인증서 갱신**: 인증서 만료 전에 새로운 인증서를 생성하고 교체하세요

3. **토큰 보안**: Registration Token은 외부에 노출되지 않도록 주의하세요

4. **네트워크 격리**: 프로덕션 환경에서는 적절한 네트워크 격리를 구성하세요

## 참고 자료

- [Thales CipherTrust 공식 문서](https://thalesdocs.com/)
- [Docker 공식 문서](https://docs.docker.com/)
- [OpenSSL 인증서 관리](https://www.openssl.org/docs/)
