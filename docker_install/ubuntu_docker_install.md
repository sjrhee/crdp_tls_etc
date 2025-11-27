# Ubuntu Docker 설치 가이드

이 가이드는 Ubuntu 시스템에 Docker Engine을 설치하는 방법을 안내합니다.

## 지원 버전

- Ubuntu Jammy 22.04 (LTS)
- Ubuntu Focal 20.04 (LTS)
- Ubuntu Bionic 18.04 (LTS)

## 사전 요구사항

- 64-bit 버전의 Ubuntu
- sudo 권한을 가진 사용자

## 설치 방법

### 1. 기존 Docker 제거 (선택사항)

기존에 설치된 Docker가 있다면 먼저 제거합니다:

```bash
sudo apt-get remove docker docker-engine docker.io containerd runc
```

### 2. 패키지 인덱스 업데이트 및 필수 패키지 설치

```bash
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
```

### 3. Docker의 공식 GPG 키 추가

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

### 4. Docker 저장소 설정

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 5. Docker Engine 설치

```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 6. Docker 설치 확인

```bash
sudo docker run hello-world
```

정상적으로 설치되었다면 "Hello from Docker!" 메시지가 출력됩니다.

## 설치 후 설정

### 1. 일반 사용자가 Docker 명령어 사용하기

sudo 없이 Docker 명령어를 사용하려면 사용자를 docker 그룹에 추가합니다:

```bash
sudo usermod -aG docker $USER
```

변경사항을 적용하려면 로그아웃 후 다시 로그인하거나 다음 명령어를 실행합니다:

```bash
newgrp docker
```

### 2. Docker 서비스 자동 시작 설정

```bash
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
```

### 3. Docker 서비스 상태 확인

```bash
sudo systemctl status docker
```

## Docker Compose 사용

Docker Compose는 이제 플러그인으로 설치됩니다. 사용 방법:

```bash
docker compose version
```

## 문제 해결

### Docker 데몬이 시작되지 않는 경우

```bash
sudo systemctl start docker
sudo journalctl -xeu docker.service
```

### 권한 오류가 발생하는 경우

사용자가 docker 그룹에 추가되었는지 확인:

```bash
groups $USER
```

## 제거 방법

Docker를 완전히 제거하려면:

```bash
# Docker 패키지 제거
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 이미지, 컨테이너, 볼륨 등 모든 데이터 삭제
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

## 참고 자료

- [Docker 공식 문서 - Ubuntu 설치](https://docs.docker.com/engine/install/ubuntu/)
- [Docker 공식 문서 - 설치 후 설정](https://docs.docker.com/engine/install/linux-postinstall/)
