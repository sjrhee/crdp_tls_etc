# Red Hat / CentOS / Rocky Linux Docker 설치 가이드

이 가이드는 Red Hat Enterprise Linux (RHEL), CentOS, Rocky Linux 시스템에 Docker Engine을 설치하는 방법을 안내합니다.

## 지원 버전

- RHEL 9 / CentOS 9 / Rocky Linux 9
- RHEL 8 / CentOS 8 / Rocky Linux 8
- RHEL 7 / CentOS 7

## 사전 요구사항

- 64-bit 버전의 RHEL/CentOS/Rocky Linux
- sudo 권한을 가진 사용자

## 설치 방법

### 1. 기존 Docker 제거 (선택사항)

기존에 설치된 Docker가 있다면 먼저 제거합니다:

```bash
sudo yum remove docker \
                docker-client \
                docker-client-latest \
                docker-common \
                docker-latest \
                docker-latest-logrotate \
                docker-logrotate \
                docker-engine \
                podman \
                runc
```

### 2. 필수 패키지 설치

```bash
sudo yum install -y yum-utils
```

### 3. Docker 저장소 설정

```bash
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

### 4. Docker Engine 설치

#### RHEL/CentOS/Rocky Linux 8/9의 경우:

```bash
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

#### RHEL/CentOS 7의 경우:

```bash
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

> **참고**: RHEL의 경우 추가로 `container-selinux` 패키지가 필요할 수 있습니다.

### 5. Docker 서비스 시작

```bash
sudo systemctl start docker
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

## SELinux 설정 (RHEL/CentOS)

SELinux가 활성화된 경우, Docker 컨테이너가 정상적으로 동작하도록 설정이 필요할 수 있습니다.

### SELinux 상태 확인

```bash
getenforce
```

### SELinux 컨텍스트 설정

Docker는 기본적으로 SELinux와 호환됩니다. 하지만 볼륨 마운트 시 문제가 발생할 수 있습니다:

```bash
# 볼륨 마운트 시 :z 또는 :Z 옵션 사용
docker run -v /host/path:/container/path:z image_name
```

- `:z` - 여러 컨테이너가 공유할 수 있는 컨텐츠
- `:Z` - 단일 컨테이너 전용 컨텐츠

## 방화벽 설정

Docker가 네트워크를 사용하려면 방화벽 설정이 필요할 수 있습니다:

```bash
# firewalld 사용 시
sudo firewall-cmd --permanent --zone=trusted --add-interface=docker0
sudo firewall-cmd --reload
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

### SELinux 관련 오류

SELinux 로그 확인:

```bash
sudo ausearch -m avc -ts recent
```

임시로 SELinux를 permissive 모드로 변경 (권장하지 않음):

```bash
sudo setenforce 0
```

## 제거 방법

Docker를 완전히 제거하려면:

```bash
# Docker 패키지 제거
sudo yum remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 이미지, 컨테이너, 볼륨 등 모든 데이터 삭제
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

## 참고 자료

- [Docker 공식 문서 - CentOS 설치](https://docs.docker.com/engine/install/centos/)
- [Docker 공식 문서 - RHEL 설치](https://docs.docker.com/engine/install/rhel/)
- [Docker 공식 문서 - 설치 후 설정](https://docs.docker.com/engine/install/linux-postinstall/)
- [Red Hat - SELinux와 Docker](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux_atomic_host/7/html/container_security_guide/docker_selinux_security_policy)
