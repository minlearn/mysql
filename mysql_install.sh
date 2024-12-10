##############

echo "Installing Dependencies"
apt-get install -y \
  sudo \
  lsb-release \
  curl \
  gnupg \
  mc
echo "Installed Dependencies"

RELEASE_REPO="mysql-8.0"
RELEASE_AUTH="mysql_native_password"
read -r -p "Would you like to install the MySQL 8.4 LTS release instead of MySQL 8.0 (bug fix track; EOL April-2026)? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
      RELEASE_REPO="mysql-8.4-lts"
      RELEASE_AUTH="caching_sha2_password"
fi

echo "Installing MySQL"
curl -fsSL https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 | gpg --dearmor  -o /usr/share/keyrings/mysql.gpg
echo "deb [signed-by=/usr/share/keyrings/mysql.gpg] http://repo.mysql.com/apt/debian $(lsb_release -sc) ${RELEASE_REPO}" >/etc/apt/sources.list.d/mysql.list
apt-get update
export DEBIAN_FRONTEND=noninteractive
apt-get install -y \
  mysql-community-client \
  mysql-community-server
echo "Installed MySQL"

echo "Configure MySQL Server"
ADMIN_PASS="$(openssl rand -base64 18 | cut -c1-13)"
mysql -uroot -p"$ADMIN_PASS" -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH $RELEASE_AUTH BY '$ADMIN_PASS'; FLUSH PRIVILEGES;"
echo "" >~/mysql.creds
echo -e "MySQL user: root" >>~/mysql.creds
echo -e "MySQL password: $ADMIN_PASS" >>~/mysql.creds
echo "MySQL Server configured"

read -r -p "Would you like to add PhpMyAdmin? <y/N> " prompt
if [[ ${prompt,,} =~ ^(y|yes)$ ]]; then
  echo "Installing phpMyAdmin"
  apt-get install -y \
    apache2 \
    php \
    php-mysqli \
    php-mbstring \
    php-zip \
    php-gd \
    php-json \
    php-curl 
	
	wget -q "https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz"
	mkdir -p /var/www/html/phpMyAdmin
	tar xf phpMyAdmin-5.2.1-all-languages.tar.gz --strip-components=1 -C /var/www/html/phpMyAdmin
	cp /var/www/html/phpMyAdmin/config.sample.inc.php /var/www/html/phpMyAdmin/config.inc.php
	SECRET=$(openssl rand -base64 24)
	sed -i "s#\$cfg\['blowfish_secret'\] = '';#\$cfg['blowfish_secret'] = '${SECRET}';#" /var/www/html/phpMyAdmin/config.inc.php
	chmod 660 /var/www/html/phpMyAdmin/config.inc.php
	chown -R www-data:www-data /var/www/html/phpMyAdmin
	systemctl restart apache2
  echo "Installed phpMyAdmin"
fi

echo "Start Service"
systemctl enable -q --now mysql
echo "Service started"


echo "Cleaning up"
apt-get -y autoremove
apt-get -y autoclean
echo "Cleaned"

###########