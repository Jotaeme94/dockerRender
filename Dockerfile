# Imagen base de PHP con Apache
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

# Instalar dependencias desde el archivo composer.lock
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Limpiar caché de Symfony en producción
RUN php bin/console cache:clear --env=prod || true

# Configurar permisos
RUN chown -R www-data:www-data /var/www/html && chmod -R 775 /var/www/html/var

# Exponer el puerto 80
EXPOSE 80

# Comando para iniciar Apache
CMD ["apache2-foreground"]
