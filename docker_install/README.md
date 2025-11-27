# Docker 설치 가이드

이 디렉토리에는 다양한 Linux 배포판에 대한 Docker 설치 가이드가 포함되어 있습니다.

## 가이드 목록

### [Ubuntu Docker 설치 가이드](ubuntu_docker_install.md)
Ubuntu 18.04, 20.04, 22.04 LTS 버전에 Docker Engine을 설치하는 방법을 안내합니다.

**주요 내용:**
- APT 저장소를 통한 Docker 설치
- GPG 키 설정 및 저장소 추가
- 설치 후 사용자 권한 설정
- Docker Compose 플러그인 사용법

### [Red Hat / CentOS / Rocky Linux Docker 설치 가이드](redhat_docker_install.md)
RHEL, CentOS, Rocky Linux에 Docker Engine을 설치하는 방법을 안내합니다.

**주요 내용:**
- YUM 저장소를 통한 Docker 설치
- SELinux 설정 및 호환성
- 방화벽 설정
- Red Hat 계열 특화 문제 해결

## 빠른 시작

### Ubuntu
```bash
# 1. 저장소 설정
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 2. Docker 설치
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 3. 사용자 권한 설정
sudo usermod -aG docker $USER
```

### Red Hat / CentOS / Rocky Linux
```bash
# 1. 저장소 설정
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# 2. Docker 설치
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 3. Docker 시작 및 활성화
sudo systemctl start docker
sudo systemctl enable docker

# 4. 사용자 권한 설정
sudo usermod -aG docker $USER
```

## 설치 확인

모든 배포판에서 동일하게 사용:

```bash
# Docker 버전 확인
docker --version

# Docker 테스트
docker run hello-world

# Docker Compose 버전 확인
docker compose version
```

## 공통 설정

### Docker 서비스 관리

```bash
# 서비스 시작
sudo systemctl start docker

# 서비스 중지
sudo systemctl stop docker

# 서비스 재시작
sudo systemctl restart docker

# 서비스 상태 확인
sudo systemctl status docker

# 부팅 시 자동 시작
sudo systemctl enable docker
```

### Docker 정보 확인

```bash
# Docker 시스템 정보
docker info

# 실행 중인 컨테이너 확인
docker ps

# 모든 컨테이너 확인
docker ps -a

# 이미지 목록 확인
docker images
```

## 추가 리소스

- [Docker 공식 문서](https://docs.docker.com/)
- [Docker Hub](https://hub.docker.com/)
- [Docker Compose 문서](https://docs.docker.com/compose/)
- [Docker 보안 가이드](https://docs.docker.com/engine/security/)

## 문제 해결

각 배포판별 상세한 문제 해결 방법은 해당 가이드 문서를 참조하세요:
- [Ubuntu 문제 해결](ubuntu_docker_install.md#문제-해결)
- [Red Hat 문제 해결](redhat_docker_install.md#문제-해결)
