# CRDP TLS Helm 배포 - 설치 가이드 (핵심)

## 📋 필수 정보

- **Kubernetes**: v1.30.14
- **Helm**: v3.x
- **CRDP 이미지**: thalesciphertrust/ciphertrust-restful-data-protection:latest
- **TLS 모드**: tls-cert-opt
- **포트**: 32382 (HTTPS), 32380 (HTTP healthz)
- **인증서 위치**: cert.pem, prikey.pem (루트 디렉토리)

---

## ✅ 3가지 핵심 설정

### 1️⃣ Base64 인증서 추가

values.yaml에 base64 인코딩된 인증서 추가:

```yaml
configuration:
  servercrt: LS0tLS1CRUdJTi... (base64 인코딩된 cert.pem)
  serverkey: LS0tLS1CRUdJTi... (base64 인코딩된 prikey.pem)
```

**인증서 준비** (필요시):
```bash
cat cert.pem | base64 -w 0
cat prikey.pem | base64 -w 0
# 결과값을 values.yaml configuration 섹션에 붙여넣기
```

---

### 2️⃣ Replicas 설정 (고가용성)

values.yaml에서:
```yaml
replicas: 2  # 2개 Pod 동시 실행
```

---

### 3️⃣ Secret을 Helm 템플릿으로 관리

#### A. `templates/secret.yaml` 생성
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ printf "%s-tls" .Release.Name }}
type: Opaque
data:
  server.crt: {{ .Values.configuration.servercrt }}
  server.key: {{ .Values.configuration.serverkey }}
```

#### B. `templates/deployment.yaml` 수정

Secret 참조 변경:
```yaml
env:
  - name: CERT_VALUE
    valueFrom:
      secretKeyRef:
        name: {{ printf "%s-tls" .Release.Name }}
        key: server.crt
  - name: KEY_VALUE
    valueFrom:
      secretKeyRef:
        name: {{ printf "%s-tls" .Release.Name }}
        key: server.key
```

**제거할 항목**:
- `TRUSTED_CA` 환경변수
- 이전의 하드코딩된 Secret 참조

---

## 🚀 설치

```bash
# 1. 기존 리소스 정리 (있을 경우)
kubectl delete secret crdp-tls-secret 2>/dev/null
helm uninstall crdp-tls 2>/dev/null

# 2. Helm 배포
cd /home/ubuntu/Work/crdp_tls_etc/crdp_tls_helm
helm install crdp-tls .

# 3. 상태 확인
kubectl get pods -l app=crdp-tls -o wide
kubectl get svc crdp-tls-service
kubectl get secret crdp-tls-tls
```

---

## ✅ 검증

```bash
# HTTPS 테스트 (포트 32380)
for i in {1..100}; do
  curl -s -k https://localhost:32382/healthz -o /dev/null && echo "✓" || echo "✗"
done
echo ""
```

**기준**: 모든 요청 성공 (✓ 또는 .)

---

## 📁 변경 파일 목록

| 파일 | 상태 | 내용 |
|------|------|------|
| `values.yaml` | ✏️ 수정 | replicas: 2, configuration 추가 |
| `templates/secret.yaml` | ➕ 생성 | Secret 리소스 정의 |
| `templates/deployment.yaml` | ✏️ 수정 | Secret 참조 변경 |

---

## 🔄 업데이트 / 삭제

```bash
# 업데이트
helm upgrade crdp-tls .

# 삭제 (모든 리소스 정리)
helm uninstall crdp-tls
```



