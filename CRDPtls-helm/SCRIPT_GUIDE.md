# 자동화 배포 스크립트 가이드

이 문서는 `deploy-crdp-tls.sh` 스크립트의 사용 방법을 설명합니다.

## 개요

`deploy-crdp-tls.sh`는 CRDP TLS Helm 차트 배포를 자동화하는 Bash 스크립트입니다.

## 📋 사전 요구사항

- Kubernetes 클러스터에 접근 권한
- `kubectl` 설치 및 구성
- `helm` 3.x 이상 설치
- Python 3.x 설치
- TLS 인증서 파일:
  - `Certificate.pem`
  - `key.pem`

## 🚀 사용 방법

### 기본 명령어

```bash
# 스크립트에 실행 권한 부여
chmod +x deploy-crdp-tls.sh

# 도움말 보기
./deploy-crdp-tls.sh help

# 설치
./deploy-crdp-tls.sh install

# 업그레이드
./deploy-crdp-tls.sh upgrade

# 상태 확인
./deploy-crdp-tls.sh status

# 검증 (설치 없이 dry-run만 수행)
./deploy-crdp-tls.sh validate

# 제거
./deploy-crdp-tls.sh uninstall
```

## 📋 스크립트 기능

### 1. **전제 조건 확인** (`check_prerequisites`)
```bash
./deploy-crdp-tls.sh install
```
스크립트 실행 시 자동으로 다음을 확인:
- `kubectl` 설치 확인
- `helm` 설치 확인
- Kubernetes 클러스터 연결 확인
- `Certificate.pem` 파일 존재 확인
- `key.pem` 파일 존재 확인

실패 시 명확한 오류 메시지 출력 후 종료

### 2. **values.yaml 생성** (`generate_values_yaml`)
```bash
./deploy-crudp-tls.sh install
```
자동으로 수행:
- `Certificate.pem`을 Base64로 인코딩
- `key.pem`을 Base64로 인코딩
- 인코딩된 값을 `values.yaml`에 저장
- 각 인증서의 크기 출력

### 3. **Helm 차트 검증** (`validate_helm_chart`)
```bash
./deploy-crdp-tls.sh validate
```
다음을 수행:
- `helm lint` - 차트 문법 검증
- `helm install --dry-run --debug` - 실제 배포 시뮬레이션
- 오류 발생 시 로그 출력

### 4. **차트 설치** (`install_chart`)
```bash
./deploy-crdp-tls.sh install
```
기능:
- 이미 설치된 릴리스 감지
- 기존 릴리스가 있으면 upgrade 옵션 제시
- 성공 시 자동으로 `status` 명령 실행

### 5. **차트 업그레이드** (`upgrade_chart`)
```bash
./deploy-crdp-tls.sh upgrade
```
기능:
- 기존 릴리스 업데이트
- 성공 시 자동으로 `status` 명령 실행

### 6. **차트 제거** (`uninstall_chart`)
```bash
./deploy-crdp-tls.sh uninstall
```
기능:
- 확인 프롬프트 표시
- 사용자 확인 후 제거
- 릴리스가 없으면 안내 메시지 출력

### 7. **상태 확인** (`show_status`)
```bash
./deploy-crdp-tls.sh status
```
출력 정보:
- Helm 릴리스 정보
- 파드 상태
- 서비스 정보
- Secret 정보
- 로그 확인 명령어

## 🔍 스크립트 구성

### 색상 코드

스크립트는 다음 색상으로 출력 구분:

| 색상 | 의미 | 함수 |
|------|------|------|
| 🔵 파란색 | 정보 | `print_info` |
| 🟢 초록색 | 성공 | `print_success` |
| 🟡 노란색 | 경고 | `print_warning` |
| 🔴 빨간색 | 오류 | `print_error` |

### 설정 변수

스크립트 상단의 다음 변수를 필요에 따라 수정 가능:

```bash
RELEASE_NAME="crdp-tls"      # Helm 릴리스 이름
CHART_PATH="."               # 차트 경로
NAMESPACE="default"          # Kubernetes 네임스페이스
CERT_FILE="Certificate.pem"  # 인증서 파일
KEY_FILE="key.pem"           # 키 파일
```

## 📝 사용 예시

### 시나리오 1: 처음 설치

```bash
# 1. 전제 조건 확인 및 값 생성, 검증, 설치
./deploy-crdp-tls.sh install

# 출력 예:
# [INFO] Checking prerequisites...
# [SUCCESS] All prerequisites met
# [INFO] Generating values.yaml with base64 encoded certificates...
# [SUCCESS] values.yaml generated successfully
# [INFO] Validating Helm chart...
# [SUCCESS] Helm chart validation passed
# [INFO] Installing Helm chart...
# [SUCCESS] Helm chart installed successfully
```

### 시나리오 2: 검증만 수행

```bash
# 배포 없이 dry-run만 실행
./deploy-crdp-tls.sh validate

# 출력 예:
# [INFO] Checking prerequisites...
# [SUCCESS] All prerequisites met
# [INFO] Generating values.yaml with base64 encoded certificates...
# [SUCCESS] values.yaml generated successfully
# [INFO] Validating Helm chart...
# [SUCCESS] Helm chart validation passed
# [SUCCESS] Validation completed successfully
```

### 시나리오 3: 인증서 업데이트 후 업그레이드

```bash
# 1. 새로운 인증서 파일로 교체
cp /path/to/new/Certificate.pem .
cp /path/to/new/key.pem .

# 2. 업그레이드
./deploy-crdp-tls.sh upgrade

# 출력 예:
# [INFO] Checking prerequisites...
# [SUCCESS] All prerequisites met
# [INFO] Generating values.yaml with base64 encoded certificates...
# [SUCCESS] values.yaml generated successfully
# [INFO] Validating Helm chart...
# [SUCCESS] Helm chart validation passed
# [INFO] Upgrading Helm chart...
# [SUCCESS] Helm chart upgraded successfully
```

### 시나리오 4: 상태 확인

```bash
./deploy-crdp-tls.sh status

# 출력 예:
# [INFO] Deployment Status:
# ====================
# 
# Release Information:
# crdp-tls        default         1     deployed
# 
# Pods:
# NAME                                   READY   STATUS    RESTARTS   AGE
# crdp-tls-deployment-7d5f6fff49-lrxhx   1/1     Running   0          3m47s
# ...
```

### 시나리오 5: 제거

```bash
./deploy-crdp-tls.sh uninstall

# 프롬프트 표시:
# Are you sure you want to uninstall 'crdp-tls'? (y/n): y
# [INFO] Uninstalling Helm chart...
# [SUCCESS] Helm chart uninstalled successfully
```

## 🔧 고급 사용법

### 다른 네임스페이스에 설치

스크립트 수정:
```bash
vi deploy-crdp-tls.sh
# NAMESPACE="default" → NAMESPACE="production"
```

### 다른 릴리스 이름으로 설치

스크립트 수정:
```bash
vi deploy-crdp-tls.sh
# RELEASE_NAME="crdp-tls" → RELEASE_NAME="my-crdp"
```

### 수동으로 설정 변수 전달 (확장 가능)

향후 업그레이드를 위해 환경변수 지원 추가 가능:
```bash
RELEASE_NAME="my-app" NAMESPACE="prod" ./deploy-crdp-tls.sh install
```

## 🐛 트러블슈팅

### 문제: "Permission denied" 오류

```bash
chmod +x deploy-crdp-tls.sh
```

### 문제: Python 명령어를 찾을 수 없음

```bash
# Python 경로 확인
which python3

# 스크립트에서 python3 경로 수정
# python3 << 'EOFPYTHON' → /usr/bin/python3 << 'EOFPYTHON'
```

### 문제: kubectl 연결 오류

```bash
# 클러스터 정보 확인
kubectl cluster-info

# kubeconfig 확인
echo $KUBECONFIG
cat ~/.kube/config
```

### 문제: 이미 존재하는 릴리스

```bash
# 옵션 1: 기존 릴리스 업그레이드
./deploy-crdp-tls.sh upgrade

# 옵션 2: 기존 릴리스 삭제 후 재설치
./deploy-crdp-tls.sh uninstall
./deploy-crdp-tls.sh install
```

## 📊 로그 확인

스크립트는 dry-run 결과를 `/tmp/helm-dry-run.log`에 저장:

```bash
# dry-run 로그 확인
cat /tmp/helm-dry-run.log
```

## ✅ 체크리스트

설치 전 확인 사항:

- [ ] Kubernetes 클러스터 접속 가능
- [ ] `kubectl` 설치됨
- [ ] `helm` 3.x 이상 설치됨
- [ ] Python 3.x 설치됨
- [ ] `Certificate.pem` 파일 존재
- [ ] `key.pem` 파일 존재
- [ ] 스크립트에 실행 권한 있음 (`chmod +x`)
- [ ] values.yaml 백업 (필요시)

## 🔗 추가 정보

- Helm 공식 문서: https://helm.sh/docs/
- Thales CRDP 공식 문서: https://thalesdocs.com/ctp/con/crdp/latest/
- Kubernetes 공식 문서: https://kubernetes.io/docs/
