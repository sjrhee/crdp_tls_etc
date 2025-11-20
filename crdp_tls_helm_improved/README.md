# CRDP TLS Helm Chart (Improved)

패킷 손실 문제를 해결한 개선된 Helm 배포 설정입니다.

## 문제 해결
- **기존**: 패킷 손실 20% (10개 중 2개 실패)
- **개선**: 패킷 손실 0% (100/100 요청 성공)

## 설치
```bash
cd crdp_tls_helm_improved
helm install crdp-tls .
```

## 주요 변경사항
1. Replicas: 1 → 2 (고가용성)
2. Secret을 Helm 템플릿으로 관리
3. Base64 인증서를 values.yaml에 중앙화

자세한 내용은 INSTALL.md를 참조하세요.
