# Sonar

# Docker 启动

docker-compose:

```
version: '2'

services:
  postgresql:
    image: 'bitnami/postgresql:10'
    environment:
      - POSTGRESQL_USERNAME=bn_sonarqube
      - POSTGRESQL_DATABASE=bitnami_sonarqube
      - POSTGRESQL_PASSWORD=bitnami1234
      - ALLOW_EMPTY_PASSWORD=yes
    volumes:
      - 'postgresql_data:/bitnami'
  sonarqube:
    image: bitnami/sonarqube:latest
    ports:
      - '9090:9000'
    environment:
      - POSTGRESQL_HOST=postgresql
      - SONARQUBE_DATABASE_NAME=bitnami_sonarqube
      - SONARQUBE_DATABASE_USER=bn_sonarqube
      - SONARQUBE_DATABASE_PASSWORD=bitnami1234
      - SONARQUBE_USERNAME=admin
      - SONARQUBE_PASSWORD=admin123
    volumes:
      - sonarqube_data:/bitnami
volumes:
  sonarqube_data:
    driver: local
  postgresql_data:
    driver: local
```

