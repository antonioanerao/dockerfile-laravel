FROM nginx

VOLUME [ "/laravel" ]
WORKDIR /laravel
ENV ACCEPT_EULA=Y

# Define a timezone padrão
RUN ln -fs /usr/share/zoneinfo/America/Rio_Branco /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

# Instala as dependências do sistema
RUN apt update && \
    apt -y upgrade && \
    echo "pt_BR.UTF-8 UTF-8" > /etc/locale.gen && \
    apt install -y ca-certificates \
                   apt-transport-https \
                   lsb-release \
                   gnupg \
                   curl \
                   wget \
                   dirmngr \
                   rsync \
                   gettext \
                   locales \
                   unzip \
                   autoconf \
                   libc-dev \
                   pkg-config

# Define a localização padrão
RUN locale-gen

# Instala o PHP 8.2, suas extensões, node, npm e composer
RUN apt -y update && \
    apt -y install --allow-unauthenticated php \
                   php-fpm \
                   php-mysql \
                   php-mbstring \
                   php-soap \
                   php-gd \
                   php-xml \
                   php-intl \
                   php-dev \
                   php-curl \
                   php-zip \
                   php-imagick \
                   php-gmp \
                   php-ldap \
                   php-bcmath \
                   php-bz2 \
                   php-phar \
                   php-sqlite3 && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer &&  \
    curl -s https://deb.nodesource.com/setup_18.x | bash && \
    apt-get update && \
    apt install nodejs -y

RUN apt-get update && \
    apt-get install -y curl gnupg ca-certificates && \
    curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb \
      -o /tmp/packages-microsoft-prod.deb && \
    dpkg -i /tmp/packages-microsoft-prod.deb && \
    rm /tmp/packages-microsoft-prod.deb && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 unixodbc-dev && \
    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;') && \
    echo ">>> PHP detectado: $PHP_VERSION" && \
    pecl install sqlsrv && \
    pecl install pdo_sqlsrv && \
    printf "; priority=20\nextension=sqlsrv.so\n" > /etc/php/$PHP_VERSION/mods-available/sqlsrv.ini && \
    printf "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/$PHP_VERSION/mods-available/pdo_sqlsrv.ini && \
    phpenmod -v $PHP_VERSION sqlsrv pdo_sqlsrv && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get upgrade -y && \
    apt-get autoremove -y && \
    apt-get clean && \
    printf "# priority=30\nservice php$PHP_VERSION-fpm start\n" > /docker-entrypoint.d/30-php$PHP_VERSION-fpm.sh && \
    chmod 755 /docker-entrypoint.d/30-php$PHP_VERSION-fpm.sh && \
    composer create-project laravel/laravel . && \
    chgrp -R www-data /laravel/storage /laravel/bootstrap/cache /laravel/storage/logs && \
    chmod -R ug+rwx /laravel/storage /laravel/bootstrap/cache /laravel/storage/logs && \
    chown root:www-data -R database && chmod ug+rwx -R database

COPY config_cntr/php.ini /tmp/php.ini
COPY config_cntr/www.conf /tmp/www.conf
COPY config_cntr/nginx.conf /tmp/nginx.conf
COPY config_cntr/default.conf /tmp/default.conf

RUN PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;') && \
    cp /tmp/php.ini /etc/php/$PHP_VERSION/fpm/php.ini && \
    cp /tmp/www.conf /etc/php/$PHP_VERSION/fpm/pool.d/www.conf && \
    cp /tmp/nginx.conf /etc/nginx/nginx.conf && \
    cp /tmp/default.conf /etc/nginx/conf.d/default.conf
