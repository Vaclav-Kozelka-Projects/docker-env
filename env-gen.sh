echo "This wizard will create new .env file for docker environment"

read -p "1. Your app local domain[default: project.test]: " PROJECT_DOMAIN
read -p "2. Non-secure Nginx port mapped to your machine [default: 80]: " PROJECT_HTTP_PORT
read -p "3. Secure Nginx port mapped to your machine [default: 443]: " PROJECT_HTTPS_PORT
read -p "4. Your app sources relative to this directory [default: ./app]: " PROJECT_LOCAL_DIR
read -p "5. Directory in container to mount app sources [default: /var/www/html]: " PROJECT_CONTAINER_DIR
read -p "6. Document root in container [default: /var/www/html]: " PROJECT_CONTAINER_DOCROOT

PROJECT_DOMAIN=${PROJECT_DOMAIN:-project.test}
envFile="PROJECT_DOMAIN=$PROJECT_DOMAIN"
PROJECT_HTTP_PORT=${PROJECT_HTTP_PORT:-80}
envFile="$envFile\nPROJECT_HTTP_PORT=$PROJECT_HTTP_PORT"
PROJECT_HTTPS_PORT=${PROJECT_HTTPS_PORT:-443}
envFile="$envFile\nPROJECT_HTTPS_PORT=$PROJECT_HTTPS_PORT"
PROJECT_LOCAL_DIR=${PROJECT_LOCAL_DIR:-./app}
envFile="$envFile\nPROJECT_LOCAL_DIR=$PROJECT_LOCAL_DIR"
PROJECT_CONTAINER_DIR=${PROJECT_CONTAINER_DIR:-/var/www/html}
envFile="$envFile\nPROJECT_CONTAINER_DIR=$PROJECT_CONTAINER_DIR"
PROJECT_CONTAINER_DOCROOT=${PROJECT_CONTAINER_DOCROOT:-/var/www/html}
envFile="$envFile\nPROJECT_CONTAINER_DOCROOT=$PROJECT_CONTAINER_DOCROOT"

read -p "7. Do you want add mysql credentials to .env file? [Y,N] " MYSQL
MYSQL=${MYSQL:-N}
if [[ $MYSQL == "Y" ]]; then
  read -p "> 1. MySQL root password [default: root]: " MYSQL_ROOT_PASS
  read -p "> 2. MySQL username [default: db_user]: " MYSQL_USER
  read -p "> 3. MySQL user password [default: db_pass]: " MYSQL_PASS
  read -p "> 4. MySQL database name [default: database]: " MYSQL_DBNAME
  read -p "> 5. MySQL port on local machine [default: 3306]: " MYSQL_PORT
  read -p "> 6. Local directory to save MySQL data [default: ./.docker/mysql]: " MYSQL_DATA

  envFile="$envFile\n"
  MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS:-root}
  envFile="$envFile\nMYSQL_ROOT_PASS=$MYSQL_ROOT_PASS"
  MYSQL_USER=${MYSQL_USER:-db_user}
  envFile="$envFile\nMYSQL_USER=$MYSQL_USER"
  MYSQL_PASS=${MYSQL_PASS:-db_pass}
  envFile="$envFile\nMYSQL_PASS=$MYSQL_PASS"
  MYSQL_DBNAME=${MYSQL_DBNAME:-database}
  envFile="$envFile\nMYSQL_DBNAME=$MYSQL_DBNAME"
  MYSQL_PORT=${MYSQL_PORT:-3306}
  envFile="$envFile\nMYSQL_PORT=$MYSQL_PORT"
  MYSQL_DATA=${MYSQL_DATA:-./.docker/mysql}
  envFile="$envFile\nMYSQL_DATA=$MYSQL_DATA"

else
  echo "Skipping mysql\n\n";
fi

echo "Your env file will be:\n-----\n$envFile\n-----\n"
read -p "Is this okay? [Y,N] " CONFIRM
CONFIRM=${CONFIRM:-N}
if [[ $CONFIRM == "Y" ]]; then
  echo $envFile > .env
  echo ".env file saved\n\n";
else
  echo "Doing nothing\n\n";
  exit 0;
fi

if [[ $MYSQL == "Y" ]]; then
  echo "
Add following lines to your docker-compose.yml file under services (adminer is optional but recomended for db and data management)

  db:
    image: mysql
    restart: always
    ports:
      - \${MYSQL_PORT}:3306
    volumes:
      - \${MYSQL_DATA}:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASS}
      MYSQL_USER: \${MYSQL_USER}
      MYSQL_PASSWORD: \${MYSQL_PASS}
      MYSQL_DATABASE: \${MYSQL_DBNAME}

  adminer:
    image: adminer
    ports:
      - 8080:8080
    depends_on:
      - db

"
fi

echo "Building SSL Certificates"
mkcert --install
mkdir -p .docker/nginx/certs && mkcert -key-file .docker/nginx/certs/ssl-cert-key.pem -cert-file .docker/nginx/certs/ssl-cert.pem "${PROJECT_DOMAIN}" "*.${PROJECT_DOMAIN}"

echo "All done. Add additional info to docker-compose.yml and /etc/hosts\n"
if [[ $MYSQL == "Y" ]]; then
  echo "
Update your docker-compose.yml file under services (adminer is optional but recommended for db and data management)

  db:
    container_name: app-db
    image: mysql
    ports:
      - \${MYSQL_PORT}:3306
    volumes:
      - \${MYSQL_DATA}:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASS}
      MYSQL_USER: \${MYSQL_USER}
      MYSQL_PASSWORD: \${MYSQL_PASS}
      MYSQL_DATABASE: \${MYSQL_DBNAME}
    networks:
      - app-network

  adminer:
    container_name: app-adminer
    image: adminer
    ports:
      - 8080:8080
    depends_on:
      - db
    networks:
      - app-network
"
fi

  echo "
Update your /etc/hosts (on windows: C:\Windows\System32\drivers\etc\hosts) file under services (adminer is optional but recommended for db and data management)

127.0.0.1   ${PROJECT_DOMAIN} www.${PROJECT_DOMAIN}

You can also add additional subdomains if your app support it. e.g. admin.${PROJECT_DOMAIN}

"

read -p "Do you want to build and run docker containers? [Y,N] " CONFIRM
CONFIRM=${CONFIRM:-N}
if [[ $CONFIRM == "Y" ]]; then
  echo "Building docker images\n"
  docker compose build --no-cache

  echo "Running project\n"
  docker compose up -d
else
  echo "Do not forget build your images before launch\n\n";
  exit 0;
fi
