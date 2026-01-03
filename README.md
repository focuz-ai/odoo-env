<h1>Odoo & IDE Visual Studio Code</h1>
Entorno de desarrollo de Odoo con IDE Visual Studio

![Odoo & Visual Studio Code](https://i.ytimg.com/vi/N1KjLdbv7kA/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLATEFBlsHpR1dYaHMiHvTApC3E4Qg)

<h1>Contenido</h1>

- [Estructura](#estructura)
    - [Estructura de config](#estructura-de-config)
    - [Estructura de módulos](#estructura-de-módulos)
- [Guía de configuración rápida:](#guía-de-configuración-rápida)
- [El archivo `.env`](#el-archivo-env)
- [Preparar entorno de desarrollo](#preparar-entorno-de-desarrollo)
  - [Script automático (Recomendado)](#script-automático-recomendado)
  - [Instalación manual](#instalación-manual)
- [Clonar repositorios de Odoo](#clonar-repositorios-de-odoo)
- [Crear entorno virtual e instalar dependencias](#crear-entorno-virtual-e-instalar-dependencias)
- [Extras de Odoo](#extras-de-odoo)
  - [Scaffold](#scaffold)
  - [Shell](#shell)
  - [Shell para usar IPython como REPL](#shell-para-usar-ipython-como-repl)
  - [Modos de desarrollo](#modos-de-desarrollo)
- [Errores comunes](#errores-comunes)
  - [OSError: \[Errno 24\] inotify instance limit reached](#oserror-errno-24-inotify-instance-limit-reached)
- [Documentación adicional](#documentación-adicional)
- [Fuentes](#fuentes)
- [Contribuciones](#contribuciones)
# Estructura
### Estructura de config
```
config/
├── client_1/                 # Client 1
│   ├── dev.config            # Staging branch config
│   ├── main.config           # Main branch config
│   └── temp.config           # Temp branch config
└── client_2/                 # Client 2
```
### Estructura de módulos
```
src/
├── dev/                      # Development Addons 
│   └── focuz-ai/             # Organization
│       ├── repository_1/     # repository 1
│       └── repository_2/     # repository 2
└── projects/                 # Client Project Addons
    ├── client_1/             # Client 1
    │   ├── dev/              # Staging branch
    │   ├── main/             # Main branch
    │   └── temp/             # Temp branch        
    └── client_2/             # Client 2
```
# Guía de configuración rápida:
**Clonar y configurar:**
```bash
git clone -b 18.0 git@github.com:focuz-ai/odoo-env.git o18-env
cd o18-env
cp .env.example .env
cp odools.toml.example odools.toml
```

**Copiar launch de VSC para ejecutar y depurar Odoo**
```bash
cp .vscode/launch.json.example .vscode/launch.json
```

**Copiar odoo.conf por proyecto / cliente**
```bash
cp config/odoo.conf.example config/odoo.conf
```

Se recomienda crear una carpeta por cada cliente / proyecto. Y crear archivo dev.conf y main.conf. Cada uno apuntando a sus respectivas ramas para hacer pruebas en local.

# El archivo `.env`
Las variables de entorno ubicado en `.env` proporcionan configuraciones dinámicas a Odoo y al proyecto en general.

Archivo de muestra `.env`
```bash
# Odoo
ODOO_TAG=18.0

# Usuario de GitHub y token de acceso para clonar repositorios privados
GITHUB_USER=Hchumpitaz
GITHUB_ACCESS_TOKEN=ghp_token
```
# Preparar entorno de desarrollo

El script `setup_env.sh` prepara automáticamente el entorno de desarrollo, instalando Python, dependencias de Odoo y PostgreSQL client.

**Distribuciones soportadas:**
- Ubuntu 22.04, 24.04
- Debian 11, 12
- Linux Mint, Pop!_OS (basados en Ubuntu)

## Script automático (Recomendado)

```bash
chmod +x setup_env.sh
./setup_env.sh
```

**Opciones disponibles:**

| Opción | Descripción |
|--------|-------------|
| `-p, --python VERSION` | Versión de Python a instalar (3.10 - 3.14). Por defecto: 3.13 |
| `-h, --help` | Mostrar ayuda |

**Ejemplos:**
```bash
./setup_env.sh                  # Instalar con Python 3.13 (por defecto)
./setup_env.sh -p 3.12          # Instalar con Python 3.12
./setup_env.sh --python 3.11    # Instalar con Python 3.11
```

**El script instala automáticamente:**
- Python (versión especificada) + pip + venv
- Dependencias de compilación y librerías de Odoo
- PostgreSQL client

## Instalación manual

Si prefieres instalar manualmente, sigue estos pasos:

<details>
<summary>Instalación de PostgreSQL client</summary>

```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install gnupg wget -y
wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
sudo apt-get update
sudo apt-get install --no-install-recommends -y postgresql-client
```

**Opcional - PostgreSQL servidor completo:**
```bash
sudo apt-get install postgresql-16 -y
```
</details>

<details>
<summary>Instalación de Python 3.13 (Ubuntu)</summary>

```bash
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.13 python3.13-dev python3.13-venv -y
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.13
```
</details>

<details>
<summary>Instalación de dependencias de Odoo</summary>

```bash
sudo apt-get install -y git build-essential wget curl gnupg lsb-release \
    libsasl2-dev libldap2-dev libssl-dev libpq-dev \
    libxml2-dev libxslt1-dev libevent-dev libffi-dev \
    libjpeg-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev \
    liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev \
    node-less
```

> **Nota:** En Ubuntu 22.04/Debian 11 usar `libtiff5-dev`. En Ubuntu 24.04/Debian 12 usar `libtiff-dev`.
</details>

# Clonar repositorios de Odoo

Para clonar el repositorio de Odoo Community, Odoo Enterprise y Themes:
```bash
chmod +x clone-addons.sh
./clone-addons.sh
```

# Crear entorno virtual e instalar dependencias

Crear entorno virtual con la versión de Python instalada:
```bash
python3.13 -m venv .venv
```

Activar entorno virtual:
```bash
source .venv/bin/activate
```

Instalar dependencias:
```bash
pip install --upgrade pip setuptools wheel
pip install -r odoo/requirements.txt
pip install -r requirements.txt
```

Desactivar entorno virtual (cuando sea necesario):
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

    >>> self.env["res.users"].browse(2).login = "sadmin"
    >>> self.env["res.users"].browse(2).password = "sadmin"
    >>> self.env.cr.commit()

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