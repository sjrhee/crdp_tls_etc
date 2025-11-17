# CRDP TLS Configuration - Helm Deployment

Thales CipherTrust Restful Data Protection (CRDP)에 TLS를 적용하여 Kubernetes에 배포하기 위한 Helm 차트입니다.

## 📋 필수 조건

### Kubernetes 환경

- Kubernetes v1.30 이상
- `kubectl` 명령어 설치 및 구성
- 클러스터에 대한 관리자 접근권

### Helm

- Helm v3.x 이상 설치

### CRDP 요구사항

- CipherTrust Manager 접근 가능 (등록 토큰 필요)
- TLS 인증서:
  - 서버 인증서 (PEM 형식): `Certificate.pem`
  - 개인 키 (PEM 형식): `key.pem`
  - CA 인증서 (선택사항): `ca.pem`

## 📁 파일 구조

```
CRDPtls-helm/
├── Chart.yaml                      # Helm 차트 메타데이터
├── values.yaml                     # 설정 값 (Base64 인코딩된 인증서 포함)
├── templates/
│   ├── deployment.yaml             # CRDP Deployment 및 Service
│   └── secret.yaml                 # TLS 인증서 Secret
├── Certificate.pem                 # 서버 인증서
├── key.pem                         # 개인 키
├── ca.pem                          # CA 인증서
├── deploy-crdp-tls.sh             # 배포 자동화 스크립트
├── README.md                       # 이 문서
└── SCRIPT_GUIDE.md                 # 스크립트 사용 가이드
```

## ⚙️ 설정

## 📜 Helm을 통한 TLS 인증서 적용 원리

### 개념적 흐름

Helm을 사용하여 TLS 인증서를 CRDP에 적용하는 프로세스는 다음과 같습니다:

```
1. 원본 인증서 파일 (PEM)
   ├─ Certificate.pem
   └─ key.pem
         ↓
2. Base64 인코딩
   ├─ 바이너리 데이터를 텍스트로 변환
   └─ YAML 저장 가능한 형식으로 변환
         ↓
3. values.yaml에 저장
   ├─ configuration.servercrt
   └─ configuration.serverkey
         ↓
4. Helm 템플릿 렌더링
   ├─ {{ .Values.configuration.servercrt }}
   └─ {{ .Values.configuration.serverkey }}
         ↓
5. Kubernetes Secret 생성
   ├─ 메타데이터: name, namespace, labels
   └─ 데이터: server.crt, server.key (Base64)
         ↓
6. Deployment에서 Secret 참조
   ├─ secretKeyRef로 Secret 데이터 연결
   └─ 환경변수로 주입: CERT_VALUE, KEY_VALUE
         ↓
7. 파드 실행 시 인증서 주입
   ├─ Secret에서 데이터 읽음
   ├─ Base64 디코딩
   └─ 환경변수에 설정
         ↓
8. CRDP 애플리케이션이 인증서 사용
   ├─ SERVER_MODE=tls-cert-opt 설정
   ├─ CERT_VALUE에서 인증서 읽음
   └─ KEY_VALUE에서 키 읽음
```

### 핵심 단계 설명

#### 1️⃣ **인증서 인코딩**

PEM 형식의 바이너리 인증서를 Base64로 인코딩하여 YAML 호환 텍스트로 변환합니다.

```
Certificate.pem (PEM 형식)
┌─────────────────────────────────┐
│ -----BEGIN CERTIFICATE-----     │
│ MIIEXjCCAkagAwIBAgIQTnbXe...   │
│ -----END CERTIFICATE-----       │
└─────────────────────────────────┘
            ↓ Base64 인코딩
┌─────────────────────────────────┐
│ LS0tLS1CRUdJTiBDRVJUSUZJ...   │
│ (한 줄의 텍스트)                  │
└─────────────────────────────────┘
```

#### 2️⃣ **values.yaml 저장**

인코딩된 값을 `values.yaml`에 저장하여 차트에서 참조 가능하게 합니다.

```yaml
# values.yaml
configuration:
  servercrt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0t...
  serverkey: LS0tLS1CRUdJTiBFQyBQUklWQVRFIEt...
```

**장점:**
- Git 등 버전 관리 시스템에 저장 가능
- 환경별 다른 인증서 적용 가능 (`-f prod-values.yaml`)
- 감사 추적(audit trail) 유지

#### 3️⃣ **Secret 리소스 생성**

Helm 템플릿이 `values.yaml`의 값을 Kubernetes Secret으로 변환합니다.

```yaml
# templates/secret.yaml (Helm 템플릿)
apiVersion: v1
kind: Secret
metadata:
  name: {{ printf "%s-tls" .Release.Name }}
  namespace: {{ .Release.Namespace }}
type: Opaque
data:
  server.crt: {{ .Values.configuration.servercrt }}
  server.key: {{ .Values.configuration.serverkey }}
```

렌더링 결과:
```yaml
# 실제 생성되는 Secret
apiVersion: v1
kind: Secret
metadata:
  name: crdp-tls-tls
  namespace: default
type: Opaque
data:
  server.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0t...
  server.key: LS0tLS1CRUdJTiBFQyBQUklWQVRFIEt...
```

**Kubernetes Secret의 역할:**
- 민감 데이터(인증서, 키) 보호
- RBAC으로 접근 제어
- 네임스페이스 레벨 격리

#### 4️⃣ **Deployment에서 Secret 참조**

Deployment의 환경변수 설정에서 Secret을 참조하여 파드에 주입합니다.

```yaml
# templates/deployment.yaml
containers:
  - name: crdp-tls-container
    env:
      - name: SERVER_MODE
        value: tls-cert-opt
      - name: CERT_VALUE
        valueFrom:
          secretKeyRef:
            name: crdp-tls-tls
            key: server.crt
      - name: KEY_VALUE
        valueFrom:
          secretKeyRef:
            name: crdp-tls-tls
            key: server.key
```

**환경변수 주입 방식:**
- `value`: 직접 값 지정
- `valueFrom.secretKeyRef`: Secret 참조

#### 5️⃣ **파드 실행 시 인증서 주입**

파드 시작 시 Kubernetes가 Secret에서 데이터를 읽고 환경변수에 설정합니다.

```
Kubernetes Secret (etcd에 저장)
├─ Data:
│  ├─ server.crt: LS0tLS1CRUdJ... (Base64 인코딩됨)
│  └─ server.key: LS0tLS1CRUdJ... (Base64 인코딩됨)
│
↓ 파드 생성 시
│
파드 환경변수 (프로세스 메모리)
├─ CERT_VALUE=-----BEGIN CERTIFICATE-----
│              MIIEXjCCAkagAwIBAgIQTnbXe...
│              -----END CERTIFICATE-----
├─ KEY_VALUE=-----BEGIN EC PRIVATE KEY-----
│            MIGkAgEBBDCnY9vn5yMVPB8...
│            -----END EC PRIVATE KEY-----
└─ SERVER_MODE=tls-cert-opt

↓ CRDP 애플리케이션 읽기
│
CRDP TLS 설정
├─ 인증서 사용 (CERT_VALUE)
├─ 개인 키 사용 (KEY_VALUE)
└─ HTTPS 연결 활성화
```

### 데이터 흐름 요약

| 단계 | 형식 | 저장 위치 | 접근 방식 |
|------|------|---------|---------|
| 원본 | PEM (텍스트) | 파일 시스템 | 파일 읽기 |
| 인코딩 | Base64 (텍스트) | values.yaml | YAML 구문 분석 |
| 저장 | Base64 (텍스트) | 파일 시스템 | 버전 관리 |
| 생성 | Secret (Base64) | Kubernetes etcd | API 호출 |
| 주입 | 환경변수 (평문) | 파드 프로세스 | 환경변수 읽기 |

## ⚙️ 설정

### values.yaml 주요 설정

```yaml
# 라벨
label: crdp-tls

# Deployment 설정
deployment:
  name: crdp-tls-deployment
  crdpContainername: crdp-tls-container
  crdpimage: thalesciphertrust/ciphertrust-restful-data-protection:latest
  replicas: 2

# 환경 변수
env:
  serverMode: tls-cert-opt           # TLS 모드 설정
  kms: 192.168.0.230                 # CipherTrust Manager IP/호스트명
  regToken: <YOUR_REGISTRATION_TOKEN>

# 서비스 설정
service:
  name: crdp-tls-service
  type: NodePort
  port: 8090                         # 클러스터 내부 포트
  nodePort: 32182                    # 외부 접근 포트 (30000-32767)
  probesPort: 8080                   # 헬스체크 포트
  nodePortForProbes: 32180

# 인증서 설정
configuration:
  servercrt: <BASE64_ENCODED_CERTIFICATE>
  serverkey: <BASE64_ENCODED_KEY>
```

## 🔐 TLS 모드 (Thales 기준)

Thales CRDP는 다음 TLS 모드를 지원합니다:

### tls-cert-opt (권장)
```yaml
env:
  serverMode: tls-cert-opt
```
- **TLS/SSL**: 활성화
- **클라이언트 인증서 검증**: 선택사항
- **설명**: 클라이언트가 인증서를 제공하지 않아도 연결 가능
- **용도**: 외부 클라이언트와의 통신, 유연한 인증 필요

### tls-cert
```yaml
env:
  serverMode: tls-cert
```
- **TLS/SSL**: 활성화
- **클라이언트 인증서 검증**: 필수
- **설명**: 클라이언트가 유효한 인증서를 제시해야 함
- **용도**: mTLS (상호 TLS) 인증 필요, 강력한 보안 필요

### no-tls
```yaml
env:
  serverMode: no-tls
```
- **TLS/SSL**: 비활성화
- **설명**: 평문 통신 (HTTPS 미사용)
- **용도**: 내부 네트워크, 테스트 환경

## 🚀 배포

### 자동화 스크립트 사용 (권장)

상세 가이드는 [SCRIPT_GUIDE.md](SCRIPT_GUIDE.md)를 참고하세요.

```bash
# 설치
./deploy-crdp-tls.sh install

# 업그레이드
./deploy-crdp-tls.sh upgrade

# 제거
./deploy-crdp-tls.sh uninstall

# 상태 확인
./deploy-crdp-tls.sh status
```

### 수동 배포

#### 1. 전제 조건 확인

```bash
kubectl cluster-info
helm version
```

#### 2. 배포

```bash
# 검증 및 드라이 런
helm install crdp-tls . --dry-run --debug

# 실제 설치
helm install crdp-tls .

# 업그레이드
helm upgrade crdp-tls .

# 제거
helm uninstall crdp-tls
```

## 🔍 배포 확인

### 릴리스 상태

```bash
# Helm 릴리스 확인
helm list
helm status crdp-tls
helm get values crdp-tls

# 출력 예:
# NAME      NAMESPACE STATUS  CHART                 APP VERSION
# crdp-tls  default   deployed Application-chart-1.0.0  1.1.0
```

### 리소스 상태

```bash
# 파드 상태
kubectl get pods -l app=crdp-tls
kubectl describe pod -l app=crdp-tls

# 서비스
kubectl get svc -l app=crdp-tls
kubectl get svc crdp-tls-service

# Secret
kubectl get secret crdp-tls-tls
kubectl describe secret crdp-tls-tls
```

### 환경변수 확인

```bash
# 파드의 환경변수 확인
kubectl describe pod -l app=crdp-tls | grep -A 15 "Environment:"

# 출력 예:
# Environment:
#   KEY_MANAGER_HOST:    192.168.0.230
#   SERVER_MODE:         tls-cert-opt
#   REGISTRATION_TOKEN:  s4NglgTjxtvzSGs0cG1mdrZXqMJ5LL0Tj9WvgPSqg8OoTeDdoLRbJUFR0FvIiGAP
#   CERT_VALUE:          <set to the key 'server.crt' in secret 'crdp-tls-tls'>
#   KEY_VALUE:           <set to the key 'server.key' in secret 'crdp-tls-tls'>
```

### 인증서 검증

```bash
# Secret에 저장된 인증서 디코딩
kubectl get secret crdp-tls-tls -o jsonpath='{.data.server\.crt}' | base64 -d

# 출력 예:
# -----BEGIN CERTIFICATE-----
# MIIEXjCCAkagAwIBAgIQTnbXeN6Le9vcBFS3FhiEezANBgkqhkiG...
# -----END CERTIFICATE-----

# 인증서 정보 상세 확인
kubectl get secret crdp-tls-tls -o jsonpath='{.data.server\.crt}' | base64 -d | openssl x509 -text -noout
```

### 로그 확인

```bash
# 최근 로그 확인
kubectl logs -l app=crdp-tls --tail=100

# 특정 파드 로그
kubectl logs <POD_NAME>

# 실시간 로그 스트리밍
kubectl logs -l app=crdp-tls -f
```

## 🔧 트러블슈팅

### 파드 시작 실패

```bash
# 파드 상태 상세 확인
kubectl describe pod <POD_NAME>

# 파드 이벤트 확인
kubectl get events --sort-by='.lastTimestamp'
```

**일반적인 원인:**
- CipherTrust Manager 연결 불가
- 잘못된 등록 토큰
- 인증서 형식 오류

### Secret 오류

```bash
# Secret 존재 확인
kubectl get secret crdp-tls-tls

# Secret 내용 확인
kubectl get secret crdp-tls-tls -o yaml

# Base64 디코딩 검증
kubectl get secret crdp-tls-tls -o jsonpath='{.data.server\.crt}' | base64 -d | head -2
```

**일반적인 원인:**
- Base64 인코딩 오류
- Secret 생성 실패

### 배포 오류

```bash
# Helm 차트 검증
helm lint .

# 드라이 런으로 YAML 확인
helm install crdp-tls . --dry-run --debug > /tmp/manifests.yaml
cat /tmp/manifests.yaml
```

### 네트워크 연결 테스트

```bash
# 파드 내에서 CipherTrust Manager 연결 테스트
kubectl exec -it <POD_NAME> -- \
  nc -zv <KMS_IP> <PORT>

# CRDP 서비스 연결 테스트
kubectl run -it test-pod --image=curlimages/curl -- \
  curl -k https://crdp-tls-service:8090/health
```

## 📚 추가 정보

### 참고 문서

- **Thales CRDP 공식 문서**: https://thalesdocs.com/ctp/con/crdp/latest/
- **TLS 설정 가이드**: https://thalesdocs.com/ctp/con/crdp/latest/admin/crdp-tasks/crdp-verify-client/index.html
- **Helm 공식 문서**: https://helm.sh/docs/
- **Kubernetes 공식 문서**: https://kubernetes.io/docs/

### 배포 자동화 스크립트

자세한 스크립트 사용 방법은 [SCRIPT_GUIDE.md](SCRIPT_GUIDE.md)를 참고하세요.

## ✅ 배포 체크리스트

- [ ] Kubernetes 클러스터 연결 확인
- [ ] `kubectl` 설치 및 구성 완료
- [ ] `helm` v3.x 설치 완료
- [ ] `Certificate.pem` 파일 준비
- [ ] `key.pem` 파일 준비
- [ ] `values.yaml`에서 KMS IP/호스트명 설정
- [ ] `values.yaml`에서 등록 토큰 설정
- [ ] `helm lint` 성공
- [ ] `helm install --dry-run` 성공
- [ ] `helm install crdp-tls .` 실행
- [ ] 파드 상태 확인 (Running)
- [ ] 로그 확인 (에러 없음)
- [ ] 환경변수 확인 (CERT_VALUE, KEY_VALUE 설정됨)

## 📝 변경 이력

### 2025-11-12 v1.0.0
- 초기 릴리스
- TLS without client authentication 지원
- Helm 자동화 배포 스크립트 포함
- Thales 공식 가이드 기준 문서화

### TLS 모드

- **tls-cert-opt**: TLS 활성화, 클라이언트 인증 선택사항 (권장)
- **tls-cert**: TLS 활성화, 클라이언트 인증 필수
- **no-tls**: TLS 비활성화

## 📜 Helm을 통한 인증서 적용 원리

### 개념적 흐름

Helm을 사용하여 TLS 인증서를 CRDP에 적용하는 과정은 다음과 같습니다:

```
1. 원본 인증서 파일 (PEM)
   ↓
2. Base64 인코딩
   ↓
3. values.yaml에 저장
   ↓
4. Helm Chart에서 템플릿화
   ↓
5. Kubernetes Secret 생성
   ↓
6. Deployment에서 Secret 참조
   ↓
7. 파드 내 환경변수로 주입
   ↓
8. CRDP 애플리케이션이 인증서 사용
```

### 세부 단계 설명

#### 1️⃣ **인증서 인코딩**
- PEM 형식의 인증서와 키 파일을 Base64로 인코딩
- Base64는 바이너리 데이터를 텍스트 형식으로 변환하는 방식
- YAML 파일에 안전하게 저장하기 위함

```
Certificate.pem (바이너리)
    ↓ Base64 인코딩
LS0tLS1CRUdJTi... (텍스트)
```

#### 2️⃣ **values.yaml에 저장**
- `configuration.servercrt`에 Base64 인코딩된 인증서 저장
- `configuration.serverkey`에 Base64 인코딩된 키 저장
- 이는 Git이나 ConfigMap에 안전하게 버전 관리 가능

```yaml
configuration:
  servercrt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0t...
  serverkey: LS0tLS1CRUdJTiBFQyBQUklWQVRFIEt...
```

#### 3️⃣ **템플릿에서 Secret 생성**
- `templates/secret.yaml`에서 values의 인증서를 참조
- Helm이 `values.yaml` 값을 템플릿에 대입 (`{{ .Values.configuration.servercrt }}`)
- Kubernetes Secret 리소스로 변환

```yaml
# templates/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ printf "%s-tls" .Release.Name }}
type: Opaque
data:
  server.crt: {{ .Values.configuration.servercrt }}
  server.key: {{ .Values.configuration.serverkey }}
```

#### 4️⃣ **Deployment에서 Secret 참조**
- `templates/deployment.yaml`의 Deployment 스펙에서 Secret을 환경변수로 참조
- Kubernetes는 Secret의 데이터를 Base64 디코딩하여 환경변수로 제공

```yaml
# templates/deployment.yaml
env:
  - name: CERT_VALUE
    valueFrom:
      secretKeyRef:
        name: crdp-tls-tls
        key: server.crt
  - name: KEY_VALUE
    valueFrom:
      secretKeyRef:
        name: crdp-tls-tls
        key: server.key
```

#### 5️⃣ **파드 실행 시 인증서 주입**
- 파드가 시작될 때 Kubernetes가 Secret에서 데이터를 읽음
- Base64로 디코딩하여 환경변수 `CERT_VALUE`, `KEY_VALUE`에 설정
- CRDP 애플리케이션이 이 환경변수를 읽어 TLS 구성

```
Secret (쿠버네티스)
  ├── server.crt: LS0tLS1CRUdJ... (Base64)
  └── server.key: LS0tLS1CRUdJ... (Base64)
         ↓ 디코딩 및 주입
파드 환경변수
  ├── CERT_VALUE: -----BEGIN CERTIFICATE-----
  └── KEY_VALUE: -----BEGIN EC PRIVATE KEY-----
         ↓ 읽기
CRDP 애플리케이션 TLS 설정
```

### 핵심 개념

| 단계 | 목적 | 기술 |
|------|------|------|
| **인코딩** | 바이너리 인증서를 텍스트로 변환 | Base64 |
| **저장** | 설정값을 구조화된 형태로 관리 | YAML (values.yaml) |
| **템플릿화** | 다양한 환경에 재사용 가능하게 구성 | Helm 템플릿 (`{{ }}`) |
| **시크릿 생성** | Kubernetes에서 민감 데이터 안전 관리 | Secret 리소스 |
| **주입** | 파드에 데이터 전달 | 환경변수 (`valueFrom.secretKeyRef`) |

### Helm의 장점

- **재사용성**: 동일한 차트로 여러 클러스터/환경에 배포
- **보안**: 인증서를 Kubernetes Secret으로 관리
- **버전 관리**: values.yaml으로 설정 히스토리 추적
- **자동화**: 복잡한 배포 프로세스 단순화
- **유연성**: 환경별로 다른 값 적용 가능 (`helm install -f prod-values.yaml`)

## 🔍 상태 확인

```bash
# Helm 릴리스 확인
helm list

# 파드 상태 확인
kubectl get pods -l app=crdp-tls

# 서비스 확인
kubectl get svc crdp-tls-service

# Secret 확인
kubectl get secret crdp-tls-tls

# 파드 로그 확인
kubectl logs -l app=crdp-tls

# 환경변수 확인
kubectl describe pod -l app=crdp-tls | grep -A 10 "Environment:"

# Secret 디코딩 확인
kubectl get secret crdp-tls-tls -o jsonpath='{.data.server\.crt}' | base64 -d
```

## 🔧 트러블슈팅

### 문제: Secret Base64 인코딩 오류

```bash
Error: illegal base64 data at input byte
```

**해결**: `deploy-crdp-tls.sh` 스크립트를 사용하여 올바른 base64 값 생성

### 문제: 파드가 시작되지 않음

```bash
kubectl describe pod -l app=crdp-tls
kubectl logs -l app=crdp-tls
```

**확인 사항**:
- CipherTrust Manager 연결 (`env.kms`)
- Registration Token 유효성 (`env.regToken`)
- 인증서 유효성

### 문제: 이미 설치된 릴리스

```bash
Error: cannot re-use a name that is still in use
```

**해결**:
```bash
helm uninstall crdp-tls
# 또는
helm upgrade crdp-tls .
```

## 📚 참고 문서

- [Thales CRDP 공식 문서](https://thalesdocs.com/ctp/con/crdp/latest/)
- [TLS 설정 가이드](https://thalesdocs.com/ctp/con/crdp/latest/admin/crdp-tasks/crdp-verify-client/index.html)
- [Helm 공식 문서](https://helm.sh/docs/)

## 🔐 보안 권장사항

1. **Secret 관리**: Secret을 안전한 Vault에 보관
2. **인증서 갱신**: 정기적으로 TLS 인증서 갱신
3. **접근 제어**: RBAC으로 접근 제한
4. **네트워크 정책**: NetworkPolicy로 트래픽 제한
5. **Registration Token**: 민감한 토큰을 환경변수 또는 Secret으로 관리

## 📝 변경 이력

### 2025-11-12
- 초기 Helm 차트 생성
- TLS without client authentication 구성
- 자동화 배포 스크립트 추가
- Secret 기반 인증서 관리 구현

## 🤝 기여

이슈나 개선 사항이 있으면 제보해주세요.
