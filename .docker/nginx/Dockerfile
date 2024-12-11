FROM nginx:1.24-bullseye

ARG PROJECT_DOMAIN
ARG PROJECT_CONTAINER_DIR

COPY templates/default.conf.template /etc/nginx/templates/default.conf.template

# Dependencies - feel free to add custom dependencies
RUN apt-get update && apt-get install -y wget
# Dependencies end

# SSL Certificates
COPY certs/ssl-cert.pem /etc/nginx/certs/ssl-cert.pem
COPY certs/ssl-cert-key.pem /etc/nginx/certs/ssl-cert-key.pem
# SSL Certifiaces end
