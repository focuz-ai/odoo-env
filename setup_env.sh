#!/bin/bash

set -e

echo -e "\e[32mActualizando SO...\e[0m"
sudo apt-get update
sudo apt-get upgrade -y

echo -e "\e[32m\nInstalación de dependencias de Odoo...\e[0m"
sudo apt-get install -y python3 python3-pip python3-cffi python3-dev python3-venv python3-wheel
sudo apt-get install -y git build-essential libsasl2-dev libldap2-dev libssl-dev libpq-dev libxml2-dev libxslt1-dev libevent-dev

echo -e "\e[32m\nInstalación Postgre SQL...\e[0m"
sudo apt-get install gnupg gnupg2 gnupg1 -y
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
sudo apt-get update
sudo apt-get install --no-install-recommends -y postgresql-client

# Crear el archivo cronjob
# (crontab -l ; echo "0 10 * * * cd $(pwd)/odoo && git pull") | crontab -
