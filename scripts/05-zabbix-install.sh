#!/bin/bash
# -------------------------------------------------------------------------
# Script: 05-zabbix-install.sh
# Description: Installs Zabbix Server 6.0 LTS with MySQL/MariaDB & Apache
# -------------------------------------------------------------------------

# 1. Install Zabbix Repository (Ubuntu 22.04 Jammy)
echo "Installing Zabbix Repository..."
wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu22.04_all.deb
sudo dpkg -i zabbix-release_6.0-4+ubuntu22.04_all.deb
sudo apt update

# 2. Install Server, Frontend, and Agent
echo "Installing Zabbix Packages..."
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# 3. Database Setup (MariaDB)
# Note: Ensure MariaDB is running (sudo systemctl start mariadb)
echo "Configuring Database..."
sudo mysql -uroot -e "create database zabbix character set utf8mb4 collate utf8mb4_bin;"
sudo mysql -uroot -e "create user zabbix@localhost identified by 'password';"
sudo mysql -uroot -e "grant all privileges on zabbix.* to zabbix@localhost;"
sudo mysql -uroot -e "set global log_bin_trust_function_creators = 1;"

# 4. Import Initial Schema
echo "Importing Zabbix Schema (This may take a moment)..."
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -ppassword zabbix

# 5. Disable Schema Import Mode
sudo mysql -uroot -e "set global log_bin_trust_function_creators = 0;"

# 6. Configure Database Password in Config File
echo "Updating Configuration..."
sudo sed -i 's/# DBPassword=/DBPassword=password/g' /etc/zabbix/zabbix_server.conf

# 7. Restart Services
echo "Starting Zabbix Services..."
sudo systemctl restart zabbix-server zabbix-agent apache2
sudo systemctl enable zabbix-server zabbix-agent apache2

echo "Zabbix Installation Complete!"
echo "Access Frontend at: http://<Monitor-IP>/zabbix"