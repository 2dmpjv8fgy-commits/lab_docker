# Лабораторная работа по работе с docker

Работа посвящена изучению технологии работы с контейнерами

## Часть I

Для сборки изолированного образа веб-приложения на базе Flask был разработан конфигурационный файл Dockerfile:

```
cat >> Dockerfile <<EOF
FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential 

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "main.py"]
EOF
```

Сборка: `docker build -t lab-docker .`

<details>
<summary>Вывод</summary>

```bash
[+] Building 5.3s (10/10) FINISHED                                                                                                                                                              docker:desktop-linux
 => [internal] load build definition from Dockerfile                                                                                                                                                            0.0s
 => => transferring dockerfile: 249B                                                                                                                                                                            0.0s
 => [internal] load metadata for docker.io/library/python:3.9-slim                                                                                                                                              5.2s
 => [internal] load .dockerignore                                                                                                                                                                               0.0s
 => => transferring context: 2B                                                                                                                                                                                 0.0s
 => [1/5] FROM docker.io/library/python:3.9-slim@sha256:2d97f6910b16bd338d3060f261f53f144965f755599aab1acda1e13cf1731b1b                                                                                        0.0s
 => => resolve docker.io/library/python:3.9-slim@sha256:2d97f6910b16bd338d3060f261f53f144965f755599aab1acda1e13cf1731b1b                                                                                        0.0s
 => [internal] load build context                                                                                                                                                                               0.0s
 => => transferring context: 204B                                                                                                                                                                               0.0s
 => CACHED [2/5] WORKDIR /app                                                                                                                                                                                   0.0s
 => CACHED [3/5] COPY app/requirements.txt ./                                                                                                                                                                   0.0s
 => CACHED [4/5] RUN pip install --no-cache-dir -r requirements.txt                                                                                                                                             0.0s
 => CACHED [5/5] COPY app/ ./                                                                                                                                                                                   0.0s
 => exporting to image                                                                                                                                                                                          0.0s
 => => exporting layers                                                                                                                                                                                         0.0s
 => => exporting manifest sha256:f1b0d9e866061b001a337ea99f33d25cdaa851f2623bfb72394e1dd2db9941e9                                                                                                               0.0s
 => => exporting config sha256:e31576ff691fd8eb1b28a08923415ff90984b7c5a8da425ef50f7b3494a27e79                                                                                                                 0.0s
 => => exporting attestation manifest sha256:064cdce03319b27a9a24d273bf123243c56415351adb583ce80ed62272860219                                                                                                   0.0s
 => => exporting manifest list sha256:5ecc17b4c9e1adb691da8c26454162caaa8861341658bad91b1eead6babe7b94                                                                                                          0.0s
 => => naming to docker.io/library/lab-docker:latest                                                                                                                                                            0.0s
 => => unpacking to docker.io/library/lab-docker:latest                                      
```
</details>

Запуск контейнера в фоновом режиме с пробросом портов и назначением имени: `docker run -d --name my_lab_container lab-docker`

<details>
<summary>Вывод</summary>

```bash
503a12e56f512b51089bb0b382c4a4a40fb86bc8d471dee307f09349991f2a4b
```
</details>

Копирование файла README.md с хост-машины внутрь запущенного контейнера: `docker cp README.md my_lab_container:/home/README.md`

<details>
<summary>Вывод</summary>

```bash
Successfully copied 6.14kB to my_lab_container:/home/README.md
```
</details>

Проверка файловой системы внутри контейнера через интерактивное подключение: `docker exec -it my_lab_container bash` `ls -l /home`

<img width="537" height="85" alt="Снимок экрана 2026-05-31 в 6 43 49 PM" src="https://github.com/user-attachments/assets/e2ccdc2a-5507-4309-871b-9328f7180117" />

Останавливаем старый контейнер: `docker stop my_lab_container`

## Часть II

Конфигурация параметров окружения и учетных записей была вынесена в изолированный файл .env:

```
cat > .env << 'EOF'
DB_HOST=db
DB_USER=lab_user
DB_PASSWORD=secret_pass
DB_NAME=lab_database
DB_ROOT_PASSWORD=secret_pass
EOF
```

Для автоматической инициализации базы данных и контроля готовности сервисов был разработан файл docker-compose.yml:

<details>
<summary>docker-compose.yml</summary>

```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  app:
    build: .
    container_name: lab_docker
    ports:
      - "5001:5000" # Добавили по заданию (внешний порт 5001, внутренний 5000)
    depends_on:
      db:
        condition: service_healthy
    environment:
      - DB_HOST=$DB_HOST
      - DB_USER=$DB_USER
      - DB_PASSWORD=$DB_PASSWORD
      - DB_NAME=$DB_NAME

  # Сервис базы данных MySQL
  db:
    image: mysql:8.0
    container_name: mysql_db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: $DB_ROOT_PASSWORD
      MYSQL_DATABASE: $DB_NAME
      MYSQL_USER: $DB_USER
      MYSQL_PASSWORD: $DB_PASSWORD
    ports:
      - "3306:3306"
    volumes:
      - db_data:/var/lib/mysql
      - ./db:/docker-entrypoint-initdb.d # Добавили по заданию для инициализации базы данных
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  db_data:
EOF
```
</details>

Запуск всей инфраструктуры в активном режиме сборки: `docker compose up --build`

<details>
<summary>Вывод</summary>

```bash
WARN[0000] /Users/aleksandrgolikov/lab_docker/docker-compose.yml: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion 
[+] down 4/4
 ✔ Container lab_docker       Removed                                                                                                                                                                            0.0s
 ✔ Container mysql_db         Removed                                                                                                                                                                            0.0s
 ✔ Network lab_docker_default Removed                                                                                                                                                                            0.2s
 ✔ Volume lab_docker_db_data  Removed                                                                                                                                                                            0.0s
WARN[0000] /Users/aleksandrgolikov/lab_docker/docker-compose.yml: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion 
[+] Building 5.7s (12/12) FINISHED                                                                                                                                                                                   
 => [internal] load local bake definitions                                                                                                                                                                      0.0s
 => => reading from stdin 514B                                                                                                                                                                                  0.0s
 => [internal] load build definition from Dockerfile                                                                                                                                                            0.0s
 => => transferring dockerfile: 249B                                                                                                                                                                            0.0s
 => [internal] load metadata for docker.io/library/python:3.9-slim                                                                                                                                              5.5s
 => [internal] load .dockerignore                                                                                                                                                                               0.0s
 => => transferring context: 2B                                                                                                                                                                                 0.0s
 => [1/5] FROM docker.io/library/python:3.9-slim@sha256:2d97f6910b16bd338d3060f261f53f144965f755599aab1acda1e13cf1731b1b                                                                                        0.0s
 => => resolve docker.io/library/python:3.9-slim@sha256:2d97f6910b16bd338d3060f261f53f144965f755599aab1acda1e13cf1731b1b                                                                                        0.0s
 => [internal] load build context                                                                                                                                                                               0.0s
 => => transferring context: 204B                                                                                                                                                                               0.0s
 => CACHED [2/5] WORKDIR /app                                                                                                                                                                                   0.0s
 => CACHED [3/5] COPY app/requirements.txt ./                                                                                                                                                                   0.0s
 => CACHED [4/5] RUN pip install --no-cache-dir -r requirements.txt                                                                                                                                             0.0s
 => CACHED [5/5] COPY app/ ./                                                                                                                                                                                   0.0s
 => exporting to image                                                                                                                                                                                          0.0s
 => => exporting layers                                                                                                                                                                                         0.0s
 => => exporting manifest sha256:c45b39161fa9506282161fd78eb33a4aaea5d4b26e7b3624c0fca32730868bad                                                                                                               0.0s
 => => exporting config sha256:4b8332a52fa1f5c8ae9c3203302ceb5cba97adc390bb9cfacd0fe93ba3c01691                                                                                                                 0.0s
 => => exporting attestation manifest sha256:9eeb0206c544a6d6840dfd0394fd8ee7b6cc16fde8a958b72400b753aafa516c                                                                                                   0.0s
 => => exporting manifest list sha256:dd5bae38dafe275a013304f7dd8774e9dc49acd8ff34af8c5cb33353b73e6389                                                                                                          0.0s
 => => naming to docker.io/library/lab_docker-app:latest                                                                                                                                                        0.0s
 => => unpacking to docker.io/library/lab_docker-app:latest                                                                                                                                                     0.0s
 => resolving provenance for metadata file                                                                                                                                                                      0.0s
[+] up 5/5
 ✔ Image lab_docker-app       Built                                                                                                                                                                              5.8s
 ✔ Network lab_docker_default Created                                                                                                                                                                            0.0s
 ✔ Volume lab_docker_db_data  Created                                                                                                                                                                            0.0s
 ✔ Container mysql_db         Created                                                                                                                                                                            0.0s
 ✔ Container lab_docker       Created                                                                                                                                                                            0.0s
Attaching to lab_docker, mysql_db
mysql_db  | 2026-05-31 11:31:04+00:00 [Note] [Entrypoint]: Entrypoint script for MySQL Server 8.0.46-1.el9 started.
Container mysql_db Waiting 
mysql_db  | 2026-05-31 11:31:04+00:00 [Note] [Entrypoint]: Switching to dedicated user 'mysql'
mysql_db  | 2026-05-31 11:31:04+00:00 [Note] [Entrypoint]: Entrypoint script for MySQL Server 8.0.46-1.el9 started.
mysql_db  | 2026-05-31 11:31:04+00:00 [Note] [Entrypoint]: Initializing database files
mysql_db  | 2026-05-31T11:31:04.692679Z 0 [Warning] [MY-011068] [Server] The syntax '--skip-host-cache' is deprecated and will be removed in a future release. Please use SET GLOBAL host_cache_size=0 instead.
mysql_db  | 2026-05-31T11:31:04.692710Z 0 [System] [MY-013169] [Server] /usr/sbin/mysqld (mysqld 8.0.46) initializing of server in progress as process 80
mysql_db  | 2026-05-31T11:31:04.695538Z 1 [System] [MY-013576] [InnoDB] InnoDB initialization has started.
mysql_db  | 2026-05-31T11:31:04.786722Z 1 [System] [MY-013577] [InnoDB] InnoDB initialization has ended.
mysql_db  | 2026-05-31T11:31:05.107681Z 6 [Warning] [MY-010453] [Server] root@localhost is created with an empty password ! Please consider switching off the --initialize-insecure option.
mysql_db  | 2026-05-31 11:31:06+00:00 [Note] [Entrypoint]: Database files initialized
mysql_db  | 2026-05-31 11:31:06+00:00 [Note] [Entrypoint]: Starting temporary server
mysql_db  | 2026-05-31T11:31:06.870844Z 0 [Warning] [MY-011068] [Server] The syntax '--skip-host-cache' is deprecated and will be removed in a future release. Please use SET GLOBAL host_cache_size=0 instead.
mysql_db  | 2026-05-31T11:31:06.871491Z 0 [System] [MY-010116] [Server] /usr/sbin/mysqld (mysqld 8.0.46) starting as process 124
mysql_db  | 2026-05-31T11:31:06.875943Z 1 [System] [MY-013576] [InnoDB] InnoDB initialization has started.
mysql_db  | 2026-05-31T11:31:06.922469Z 1 [System] [MY-013577] [InnoDB] InnoDB initialization has ended.
mysql_db  | 2026-05-31T11:31:06.979332Z 0 [Warning] [MY-010068] [Server] CA certificate ca.pem is self signed.
mysql_db  | 2026-05-31T11:31:06.979349Z 0 [System] [MY-013602] [Server] Channel mysql_main configured to support TLS. Encrypted connections are now supported for this channel.
mysql_db  | 2026-05-31T11:31:06.980172Z 0 [Warning] [MY-011810] [Server] Insecure configuration for --pid-file: Location '/var/run/mysqld' in the path is accessible to all OS users. Consider choosing a different directory.
mysql_db  | 2026-05-31T11:31:06.985256Z 0 [System] [MY-011323] [Server] X Plugin ready for connections. Socket: /var/run/mysqld/mysqlx.sock
mysql_db  | 2026-05-31T11:31:06.985295Z 0 [System] [MY-010931] [Server] /usr/sbin/mysqld: ready for connections. Version: '8.0.46'  socket: '/var/run/mysqld/mysqld.sock'  port: 0  MySQL Community Server - GPL.
mysql_db  | 2026-05-31 11:31:06+00:00 [Note] [Entrypoint]: Temporary server started.
mysql_db  | '/var/lib/mysql/mysql.sock' -> '/var/run/mysqld/mysqld.sock'
mysql_db  | Warning: Unable to load '/usr/share/zoneinfo/iso3166.tab' as time zone. Skipping it.
mysql_db  | Warning: Unable to load '/usr/share/zoneinfo/leap-seconds.list' as time zone. Skipping it.
mysql_db  | Warning: Unable to load '/usr/share/zoneinfo/leapseconds' as time zone. Skipping it.
mysql_db  | Warning: Unable to load '/usr/share/zoneinfo/tzdata.zi' as time zone. Skipping it.
mysql_db  | Warning: Unable to load '/usr/share/zoneinfo/zone.tab' as time zone. Skipping it.
mysql_db  | Warning: Unable to load '/usr/share/zoneinfo/zone1970.tab' as time zone. Skipping it.
mysql_db  | 2026-05-31 11:31:07+00:00 [Note] [Entrypoint]: Creating database lab_database
mysql_db  | 2026-05-31 11:31:07+00:00 [Note] [Entrypoint]: Creating user lab_user
mysql_db  | 2026-05-31 11:31:07+00:00 [Note] [Entrypoint]: Giving user lab_user access to schema lab_database
mysql_db  | 
mysql_db  | 2026-05-31 11:31:07+00:00 [Note] [Entrypoint]: /usr/local/bin/docker-entrypoint.sh: running /docker-entrypoint-initdb.d/init.sql
mysql_db  | 
mysql_db  | 
mysql_db  | 2026-05-31 11:31:07+00:00 [Note] [Entrypoint]: Stopping temporary server
mysql_db  | 2026-05-31T11:31:07.594710Z 14 [System] [MY-013172] [Server] Received SHUTDOWN from user root. Shutting down mysqld (Version: 8.0.46).
mysql_db  | 2026-05-31T11:31:08.598231Z 0 [System] [MY-010910] [Server] /usr/sbin/mysqld: Shutdown complete (mysqld 8.0.46)  MySQL Community Server - GPL.
mysql_db  | 2026-05-31 11:31:09+00:00 [Note] [Entrypoint]: Temporary server stopped
mysql_db  | 
mysql_db  | 2026-05-31 11:31:09+00:00 [Note] [Entrypoint]: MySQL init process done. Ready for start up.
mysql_db  | 
mysql_db  | 2026-05-31T11:31:09.748642Z 0 [Warning] [MY-011068] [Server] The syntax '--skip-host-cache' is deprecated and will be removed in a future release. Please use SET GLOBAL host_cache_size=0 instead.
mysql_db  | 2026-05-31T11:31:09.748976Z 0 [System] [MY-010116] [Server] /usr/sbin/mysqld (mysqld 8.0.46) starting as process 1
mysql_db  | 2026-05-31T11:31:09.751030Z 1 [System] [MY-013576] [InnoDB] InnoDB initialization has started.
mysql_db  | 2026-05-31T11:31:09.790008Z 1 [System] [MY-013577] [InnoDB] InnoDB initialization has ended.
mysql_db  | 2026-05-31T11:31:09.837347Z 0 [Warning] [MY-010068] [Server] CA certificate ca.pem is self signed.
mysql_db  | 2026-05-31T11:31:09.837364Z 0 [System] [MY-013602] [Server] Channel mysql_main configured to support TLS. Encrypted connections are now supported for this channel.
mysql_db  | 2026-05-31T11:31:09.838139Z 0 [Warning] [MY-011810] [Server] Insecure configuration for --pid-file: Location '/var/run/mysqld' in the path is accessible to all OS users. Consider choosing a different directory.
mysql_db  | 2026-05-31T11:31:09.842805Z 0 [System] [MY-011323] [Server] X Plugin ready for connections. Bind-address: '::' port: 33060, socket: /var/run/mysqld/mysqlx.sock
mysql_db  | 2026-05-31T11:31:09.842835Z 0 [System] [MY-010931] [Server] /usr/sbin/mysqld: ready for connections. Version: '8.0.46'  socket: '/var/run/mysqld/mysqld.sock'  port: 3306  MySQL Community Server - GPL.
Container mysql_db Healthy 
lab_docker  |  * Serving Flask app 'app'
lab_docker  |  * Debug mode: off
lab_docker  | WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
lab_docker  |  * Running on all addresses (0.0.0.0)
lab_docker  |  * Running on http://127.0.0.1:5000
lab_docker  |  * Running on http://172.18.0.3:5000
lab_docker  | Press CTRL+C to quit
lab_docker  | 192.168.65.1 - - [31/May/2026 11:33:52] "GET / HTTP/1.1" 200 -
lab_docker  | 192.168.65.1 - - [31/May/2026 11:33:52] "GET /favicon.ico HTTP/1.1" 404 -
```
</details>

<img width="1512" height="982" alt="Снимок экрана 2026-06-03 в 11 44 53 PM" src="https://github.com/user-attachments/assets/828a5641-5e25-41f4-b7b9-fa3ecf0d59e7" />

Закрываем контейнеры: `docker compose down`

<details>
<summary>Вывод</summary>

```bash
WARN[0000] /Users/aleksandrgolikov/lab_docker/docker-compose.yml: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion 
[+] down 3/3
 ✔ Container lab_docker       Removed                                                                                                                                                                            1.2s
 ✔ Container mysql_db         Removed                                                                                                                                                                            1.2s
 ✔ Network lab_docker_default Removed     
```
</details>
