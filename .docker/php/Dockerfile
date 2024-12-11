FROM php:8.3-fpm-bullseye

ARG PROJECT_CONTAINER_DIR
ARG APP_ID=1000

RUN groupadd -g "$APP_ID" app
RUN useradd --gid app -u "$APP_ID" -d "/home/app" -s /bin/bash -m app

# Symfony CLI
RUN curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash
# Symfony CLI end

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
# Composer end

# Dependencies - feel free to add custom dependencies
RUN apt-get update && apt-get install -y git wget libicu-dev libzip-dev zip libfreetype-dev libjpeg62-turbo-dev libpng-dev symfony-cli
# Dependencies end

# PHP Extensions - feel free to add custom extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg &&  \
    docker-php-ext-install -j$(nproc) gd opcache mysqli pdo pdo_mysql intl zip &&  \
    docker-php-ext-enable pdo_mysql intl zip
# PHP Extensions end

# Custom PHP.ini
COPY conf/custom-php.ini /usr/local/etc/php/conf.d/custom-php.ini
# Custom PHP.ini end

# GIT Settings - for composer and project auto initializing (e.g. Symfony, Laravel both creating git repository)
RUN git config --global user.email "vkozelka@gmail.com" && git config --global user.name "Vaclav Kozelka"
# GIT Settings end

RUN mkdir -p $PROJECT_CONTAINER_DIR
RUN chown -R app:app $PROJECT_CONTAINER_DIR

USER app:app

EXPOSE 9000
CMD ["php-fpm"]