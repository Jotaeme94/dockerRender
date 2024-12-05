FROM php:8.2-apache

# Instalar extensiones necesarias
RUN apt-get update && apt-get install -y \
    git unzip libicu-dev libzip-dev libonig-dev && \
    docker-php-ext-install intl zip mbstring pdo pdo_mysql

# Copiar Composer desde la imagen oficial
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configurar DocumentRoot
WORKDIR /var/www/html

# Copiar los archivos del proyecto
COPY . .

# Crear los directorios necesarios
RUN mkdir -p /var/www/html/var && \
    mkdir -p /var/www/html/public

# Instalar dependencias desde composer.lock y desactivar scripts automáticos
RUN composer install --no-dev --optimize-autoloader --no-cache

# Limpiar caché de Symfony en producción (sin fallar si algo falta)
RUN php bin/console cache:clear --env=prod || true

# Configurar permisos adecuados para Symfony
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 775 /var/www/html/var && \
    chmod -R 775 /var/www/html/public

# Copiar configuración personalizada de Apache
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf

# Habilitar el nuevo VirtualHost de Apache
RUN a2ensite 000-default.conf && a2enmod rewrite

# Exponer el puerto 80
EXPOSE 80

# Comando para iniciar Apache
CMD ["apache2-foreground"]
