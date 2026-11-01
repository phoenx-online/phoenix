#!/bin/bash
set -e
APP_NAME="phoenix"
APP_PATH="/var/www/$APP_NAME"
REPO_URL="https://github.com/<your-org>/phoenix-enterprise-core.git"

apt update && apt upgrade -y
apt install -y nginx php8.2-fpm php8.2-cli php8.2-mbstring php8.2-xml php8.2-bcmath php8.2-pdo php8.2-mysql php8.2-zip php8.2-gd php8.2-curl git curl composer nodejs npm certbot python3-certbot-nginx

# Clone repo
rm -rf $APP_PATH
git clone $REPO_URL $APP_PATH
cd $APP_PATH

cp .env.example .env || true
composer install --no-dev -o || true
php artisan key:generate || true
php artisan migrate --force || true
php artisan db:seed --class=AdminUserSeeder || true
npm install || true
npm run build || true

# Permissions
chown -R www-data:www-data $APP_PATH
chmod -R 775 $APP_PATH/storage $APP_PATH/bootstrap/cache

# Nginx config
cp deploy/nginx_phoenix.conf /etc/nginx/conf.d/phoenix.conf
nginx -t && systemctl restart nginx

# SSL (requires domain pointed to server)
# certbot --nginx -d phoenx.live -d www.phoenx.live --non-interactive --agree-tos -m admin@phoenx.live
echo "Deployment script finished."
