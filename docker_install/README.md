# Docker Installation & CRDP Scripts

이 디렉토리는 Docker 설치 가이드와 CRDP(CipherTrust Restful Data Protection) 실행 스크립트를 포함합니다.

## 문서 (Documents)

- **[Ubuntu Docker 설치 가이드](ubuntu_docker_install.md)**
  - Ubuntu 시스템에 Docker를 설치하는 상세 가이드입니다.
  
- **[Red Hat Docker 설치 가이드](redhat_docker_install.md)**
  - RHEL/CentOS/Rocky Linux 시스템에 Docker를 설치하는 상세 가이드입니다.

- **[CRDP TLS 가이드](CRDP_TLS_GUIDE.md)**
  - TLS 모드로 CRDP를 실행하기 위한 인증서 생성 및 설정 가이드입니다.

## 스크립트 (Scripts)

- **`generate_pem_files.sh`**
  - TLS 인증서 및 키 파일을 생성하여 `keys/` 폴더에 저장하는 스크립트입니다.

- **`run_crdp_tls_docker.sh`**
  - 생성된 인증서를 사용하여 TLS 모드(HTTPS)로 CRDP 컨테이너를 실행하는 스크립트입니다.

- **`run_crdp_docker.sh`**
  - TLS 없이 일반 모드(HTTP)로 CRDP 컨테이너를 실행하는 스크립트입니다.

## 디렉토리 (Directories)

- **`keys/`**
  - `generate_pem_files.sh` 스크립트로 생성된 PEM 파일들이 저장되는 폴더입니다.
