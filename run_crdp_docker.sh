docker run -d -e KEY_MANAGER_HOST=192.168.0.230 -e REGISTRATION_TOKEN=U3Sca0xJYr1QHXFWJGBA15uXGmMNnDdV0syeCOXt6LjXa8PYtbxyuyWmuL9P1IrA \
--restart unless-stopped -p 32082:8090 -p 32080:8080 -e SERVER_MODE=no-tls thalesciphertrust/ciphertrust-restful-data-protection
