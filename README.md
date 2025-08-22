<h1>Odoo & IDE Visual Studio Code</h1>
Entorno de desarrollo de Odoo con IDE Visual Studio

![Odoo & Visual Studio Code](https://i.ytimg.com/vi/N1KjLdbv7kA/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLATEFBlsHpR1dYaHMiHvTApC3E4Qg)

<h1>Contenido</h1>

- [Guía de configuración rápida:](#guía-de-configuración-rápida)
- [El archivo `.env`](#el-archivo-env)
- [Preparar entorno de desarrollo](#preparar-entorno-de-desarrollo)
  - [Script para preparar entorno de desarrollo automaticamente](#script-para-preparar-entorno-de-desarrollo-automaticamente)
  - [Forma manual para preparar entorno de desarrollo](#forma-manual-para-preparar-entorno-de-desarrollo)
    - [Instalación de requisitos en maquina local](#instalación-de-requisitos-en-maquina-local)
  - [Clonar el repositorios de Odoo](#clonar-el-repositorios-de-odoo)
  - [Crear un entorno virtual](#crear-un-entorno-virtual)
    - [Instalar las dependencias de Odoo](#instalar-las-dependencias-de-odoo)
- [Extras de Odoo](#extras-de-odoo)
  - [Scaffold](#scaffold)
  - [Shell](#shell)
  - [Shell para usar IPython como REPL](#shell-para-usar-ipython-como-repl)
- [Errores comunes](#errores-comunes)
  - [OSError: \[Errno 24\] inotify instance limit reached](#oserror-errno-24-inotify-instance-limit-reached)
- [Documentación adicional](#documentación-adicional)
- [Fuentes](#fuentes)
- [Contribuciones](#contribuciones)

# Guía de configuración rápida:
**Clonar y configurar:**
```bash
git clone git@github.com:focuzai/odoo_vsc.git
cd odoo_vsc
cp .env.example .env
```

**Copiar launch de VSC para ejecutar y depurar Odoo**
```bash
cp .vscode/launch.json.example .vscode/launch.json
```

**Copiar odoo.conf por proyecto**
```bash
cp config/odoo.conf.example config/odoo.conf
```

# El archivo `.env`
Las variables de entorno ubicado en `.env` proporcionan configuraciones dinámicas a Odoo y al proyecto en general.

Archivo de muestra `.env`
```bash
# Odoo
ODOO_TAG=16.0

# Usuario de GitHub y token de acceso para clonar repositorios privados
GITHUB_USER=Hchumpitaz
GITHUB_ACCESS_TOKEN=ghp_token
```
# Instalar Python 3.11

Ejecutar comandos para instalar Python 3.11.

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.11 -y
sudo apt install python3.11-distutils -y
sudo apt install python3.11-dev python3.11-venv -y
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11
```

# Preparar entorno de desarrollo
Ejecutar el script `setup_env.sh` para preparar el entorno de desarrollo local. 

*Instalador preparado para Ubuntu 22.04 y Ubuntu 24.04.*

## Script para preparar entorno de desarrollo automaticamente

```bash
chmod +x setup_env.sh
./setup_env.sh
```

## Forma manual para preparar entorno de desarrollo

**Si ha ejecutado el script `setup_env.sh` ir a [Clonar el repositorios de Odoo](#clonar-el-repositorios-de-odoo)**

### Instalación de requisitos en maquina local
**Instalación de PostgreSQL**
```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install gnupg gnupg2 gnupg1 -y
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
sudo apt-get update
sudo apt-get install --no-install-recommends -y postgresql-client
```
**Opcional instalar PostgreSQL completo:**

    sudo apt-get install postgresql-16 -y

**Instalación de dependencias:**

Inicia instalando las dependencias de Odoo oficial. Si al instalar las librerias de Odoo ocurre algun problema recien migrar las depedencias de **Rafnixg** o **Yenthe666**.

**Odoo**
```bash
sudo apt-get install -y python3 python3-pip python3-cffi python3-dev python3-venv python3-wheel
sudo apt-get install -y git build-essential libsasl2-dev libldap2-dev libssl-dev libpq-dev libxml2-dev libxslt1-dev libevent-dev
```

**Rafnixg**
```bash
sudo apt install python3-dev python3-pip python3-venv libxml2-dev \
    libxslt1-dev libldap2-dev libsasl2-dev libtiff5-dev \
    libjpeg8-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev \
    liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev libpq-dev libssl-dev
```

**Yenthe666**
```bash
sudo apt-get install python3 python3-pip -y
sudo apt-get install git python3-cffi build-essential wget python3-dev python3-venv python3-wheel libxslt-dev libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libpng-dev libjpeg-dev gdebi -y
```
## Clonar el repositorios de Odoo

Para clonar el repositorio de Odoo Community, Odoo Enterprise y Themes:
```bash
chmod +x clone-addons.sh
./clone-addons.sh
```
## Crear un entorno virtual

Para crear un entorno virtual de Python para Odoo (>= python3.11), ejecute el siguiente comando:
```bash
python3.11 -m venv venv
```

### Instalar las dependencias de Odoo
Para instalar las dependencias de python para Odoo, ejecute los siguientes comandos:

Activar entorno virtual `venv`.

```bash
source venv/bin/activate
```

Actualiza las librerias pip, setuptools y wheel:

```bash
pip3 install --upgrade pip setuptools wheel --no-cache-dir
pip3 install pydevd-odoo nox
```

Instalar las librerias de Odoo:
```bash
pip3 install -r odoo/requirements.txt --no-cache-dir
```

Instalas las librerias adicionales:
```bash
pip3 install -r requirements.txt --no-cache-dir
```

Si desea desactivar el entorno virtual, ejecuta:

**_Solo si deseas cambiar de entorno virtual._**
```bash
deactivate
```

# Extras de Odoo
## Scaffold

Ubicarse en la raiz del proyecto y ejecutar:

Para Linux y MAC el comando:
```bash
python odoo/odoo-bin scaffold name_module src/addons/
```
Para Windows el comando:
```bash
python.exe odoo/odoo-bin scaffold name_module src/addons/
```
## Shell

Para acceder a la shell de Odoo en Linux o Mac:
```bash
python odoo/odoo-bin shell -d <nombrebd> -c config/odoo.conf
```
Si ves “>>>”, entonces ya te encuentras en la línea de comandos de Odoo

Ejemplo de como cambiar la clave del administrador:

    >>> self.env[“res.users”].browse(2).password = "admin"
    >>> selv.env.cr.commit()

## Shell para usar IPython como REPL

IPython es un shell interactivo de Python que proporciona funciones avanzadas como autocompletado, resaltado de sintaxis, historial de comandos y más. Utilizar IPython como REPL (Read-Eval-Print Loop) en lugar del shell estándar de Python puede mejorar nuestra experiencia de programación en Odoo.

Instala IPython en tu sistema:
```bash
pip install ipython
```

Ahora que IPython está instalado, ejecutar:
```bash
odoo/odoo-bin shell -c config/odoo.conf -d <db-name> --xmlrpc-port 8888 --gevent-port 8899 --shell-interface ipython
```
## Modos de desarrollo
El parámetro ``--dev`` en Odoo se utiliza para habilitar diferentes modos de desarrollo que facilitan la depuración y el desarrollo de módulos. Algunos de los valores comunes que puede tomar son:
- all: Activa todas las opciones de desarrollo.
- assets: Habilita la depuración de archivos estáticos como CSS y JavaScript.
- qweb: Permite la depuración de plantillas QWeb.
- xml: Activa la depuración de vistas XML.
- rpc: Muestra las llamadas RPC (Remote Procedure Call) en la consola.
- pdb: Inicia un depurador interactivo (Python Debugger) en caso de errores.
# Errores comunes
## OSError: [Errno 24] inotify instance limit reached

```bash
sudo nano /etc/sysctl.conf
fs.inotify.max_user_instances = 1100000
sudo sysctl -p
```

# Documentación adicional

Por favor, consulte la [sección de documentos](https://github.com/focuzai/odoo_vsc/tree/main/docs).

# Fuentes

- [Manejo de dependencias con Submódulos](https://training.github.com/downloads/es_ES/submodule-vs-subtree-cheat-sheet/)
- [Git-submodule](https://git-scm.com/docs/git-submodule)
- [Actualizar los submódulso git de un proyecto](https://mascandobits.es/programacion/actualizar-los-submodulos-git-de-un-proyecto/)
- [Atlassian | Submódulos de Git](https://www.atlassian.com/es/git/tutorials/git-submodule)
- [Actualización de submódulo en Git](https://www.delftstack.com/es/howto/git/submodule-update-in-git/)
- [Creando un entorno de desarrollo para Odoo 14.0 con VSCode en Ubuntu 22.04](https://blog.rafnixg.dev/creando-un-entorno-de-desarrollo-para-odoo-140-con-vscode-en-ubuntu-2204)
- [Explorando Odoo a fondo: Cómo trabajar con la shell de la CLI y configurar IPython como REPL](https://blog.rafnixg.dev/explorando-odoo-a-fondo-como-trabajar-con-la-shell-de-la-cli-y-configurar-ipython-como-repl)
- [Archivo de configuración odoo.conf](https://wiki.nuxpy.com/index.php/Archivo_de_configuraci%C3%B3n_odoo.conf)
- [How to Install NVM on Ubuntu 22.04](https://www.geeksforgeeks.org/how-to-install-nvm-on-ubuntu-22-04/)

# Contribuciones

- [Harrison Chumpitaz](mailto:hchumpitaz92@gmail.com)