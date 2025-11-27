# keys 폴더

이 폴더는 `generate_pem_files.sh` 스크립트로 생성된 TLS 인증서 및 키 파일을 저장합니다.

## 생성되는 파일

- `cert.pem` - 서버 인증서
- `key.pem` - 서버 개인키
- `ca.pem` - CA 인증서 (신뢰할 수 있는 CA)
- `ca-key.pem` - CA 개인키

## 보안 주의사항

⚠️ **중요**: 이 폴더의 파일들은 민감한 정보를 포함하고 있습니다.

- `key.pem`과 `ca-key.pem`은 절대 외부에 공유하지 마세요
- Git 저장소에 커밋하지 마세요 (`.gitignore`에 추가됨)
- 적절한 파일 권한이 설정되어 있는지 확인하세요

## 파일 권한

스크립트는 자동으로 다음 권한을 설정합니다:

```bash
chmod 600 ca-key.pem key.pem  # 소유자만 읽기/쓰기
chmod 644 ca.pem cert.pem      # 소유자 읽기/쓰기, 그룹/기타 읽기만
```
