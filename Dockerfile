FROM php:8.2-apache

# Instalar extensiones necesarias
RUN apt-get update && apt-get install -y \
    git unzip libicu-dev libzip-dev libonig-dev && \
    docker-php-ext-install intl zip mbstring pdo pdo_mysql

# Copiar Composer desde la imagen oficial
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configurar DocumentRoot
WORKDIR /var/www/html
COPY . .

# Crear el directorio var/ si no existe
RUN mkdir -p /var/www/html/var && \
    mkdir -p /var/www/html/public

# Verificar que el archivo .env existe
RUN ls -l /var/www/html/.env

# Instalar dependencias desde composer.lock y desactivar scripts automáticos
RUN composer install --no-dev --optimize-autoloader --no-cache

# Limpiar caché de Symfony en producción (sin fallar si algo falta)
RUN php bin/console cache:clear --env=prod || true

# Configurar permisos adecuados para Symfony
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 775 /var/www/html/var && \
    chmod -R 775 /var/www/html/public

# Configurar Apache para servir desde el directorio public/
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf

# Habilitar el VirtualHost y mod_rewrite
RUN a2ensite 000-default.conf && a2enmod rewrite

# Verificar dependencias instaladas
RUN ls -l /var/www/html/vendor

# Exponer el puerto 80
EXPOSE 80

# Comando para iniciar Apache
CMD ["apache2-foreground"]
