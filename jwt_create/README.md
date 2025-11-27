# JWT Creation Tools

이 디렉토리는 JWT(JSON Web Token) 생성 및 관리를 위한 도구를 포함합니다.

## 스크립트 (Scripts)

- **`generate_keys.sh`**
  - JWT 서명에 사용할 공개키/개인키 쌍을 생성하는 스크립트입니다.
  - `config.yaml`의 설정을 따릅니다.

- **`create_jwt.py`**
  - Python을 사용하여 JWT 토큰을 생성하는 스크립트입니다.
  - `config.yaml`의 설정을 사용하여 토큰을 생성하고 `keys/` 폴더에 저장합니다.

## 설정 (Configuration)

- **`config.yaml`**
  - JWT 생성에 필요한 모든 설정(알고리즘, 발급자, 사용자 ID, 유효기간 등)을 담고 있는 파일입니다.

## 디렉토리 (Directories)

- **`keys/`**
  - 생성된 키 파일(`*.pem`)과 토큰 파일(`jwt_token.txt`)이 저장되는 폴더입니다.
