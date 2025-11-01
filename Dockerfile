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
                   vim \
                   dirmngr \
                   rsync \
                   gettext \
                   locales \
                   gcc \
                   g++ \
                   make \
                   unzip \
                   gcc \
                   g++ \
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

RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    apt-get install -y msodbcsql18 && \
    apt-get install -y unixodbc-dev && \
    pecl install sqlsrv && \
    pecl install pdo_sqlsrv && \
    printf "; priority=20\nextension=sqlsrv.so\n" > /etc/php/8.2/mods-available/sqlsrv.ini && \
    printf "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/8.2/mods-available/pdo_sqlsrv.ini && \
    phpenmod -v 8.2 sqlsrv pdo_sqlsrv && \
    rm -rf /var/lib/apt/lists/* && \
    apt upgrade -y && \
    apt autoremove -y && \
    apt clean && \
    printf "# priority=30\nservice php8.2-fpm start\n" > /docker-entrypoint.d/30-php8.2-fpm.sh && \
    chmod 755 /docker-entrypoint.d/30-php8.2-fpm.sh && \
    chmod 755 /docker-entrypoint.d/30-php8.2-fpm.sh && \
    composer create-project laravel/laravel . && \
    chgrp -R www-data /laravel/storage /laravel/bootstrap/cache /laravel/storage/logs && \
    chmod -R ug+rwx /laravel/storage /laravel/bootstrap/cache /laravel/storage/logs && \
    chown root:www-data -R database && chmod ug+rwx -R database

COPY config_cntr/php.ini /etc/php/8.2/fpm/php.ini
COPY config_cntr/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY config_cntr/nginx.conf /etc/nginx
COPY config_cntr/default.conf /etc/nginx/conf.d
