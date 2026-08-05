#!/bin/bash
# Базовая настройка сервера chrysotile (безопасность + Redis + кэш WP).
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "==> Swap 2GB"
if ! swapon --show | grep -q '/swapfile'; then
  fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

echo "==> UFW"
apt-get update -qq
apt-get install -y -qq ufw fail2ban redis-server php8.3-redis unattended-upgrades
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "==> Redis"
systemctl enable redis-server
systemctl restart redis-server
redis-cli ping

echo "==> OPcache JIT"
PHP_INI=/etc/php/8.3/apache2/php.ini
if ! grep -q 'chrysotile_jit' "$PHP_INI"; then
  cat >> "$PHP_INI" <<'EOF'

; chrysotile_jit
opcache.jit=tracing
opcache.jit_buffer_size=64M
opcache.memory_consumption=192
opcache.max_accelerated_files=20000
EOF
fi

echo "==> WP Redis plugin"
cd /var/www/html
if ! wp --allow-root plugin is-installed redis-cache; then
  wp --allow-root plugin install redis-cache --activate
fi
wp --allow-root redis enable 2>/dev/null || true

echo "==> mu-plugins dir"
mkdir -p /var/www/html/wp-content/mu-plugins
chown -R www-data:www-data /var/www/html/wp-content/mu-plugins

echo "==> Restart services"
systemctl restart redis-server apache2

echo "DONE"
