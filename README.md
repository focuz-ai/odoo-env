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

**Copiar launch de VSCode para ejecutar y depurar Odoo**
```bash
cp .vscode/launch.json.example .vscode/launch.json
```

Editar `launch.json` y reemplazar los placeholders:
- `<database>` → nombre de tu base de datos
- `<module_name>` → nombre del módulo a instalar/actualizar/testear

**Configuraciones disponibles en launch.json:**

| Configuración | Descripción |
|---------------|-------------|
| `Odoo: Development` | Servidor con hot reload (`--dev=all`) |
| `Odoo: Install Module` | Instalar módulo y salir |
| `Odoo: Update Module` | Actualizar módulo y salir |
| `Odoo: Run Tests` | Ejecutar tests del módulo |
| `Odoo: Shell (IPython)` | Shell interactivo con IPython |
| `Odoo: Scaffold Module` | Crear estructura de nuevo módulo |

**Configuración del workspace (settings.json):**

El archivo `.vscode/settings.json` ya viene preconfigurado con:

| Setting | Valor | Descripción |
|---------|-------|-------------|
| `python.languageServer` | `None` | Permite que Odoo IDE maneje la resolución |
| `odoo.selectedProfile` | `""` | Deshabilita extensión oficial (evita conflictos) |
| `editor.quickSuggestions.strings` | `on` | Autocompletado en strings (XML IDs) |

**Extensión requerida:** [Odoo IDE](https://marketplace.visualstudio.com/items?itemName=trinhanhngoc.vscode-odoo)
- Resolución de `_inherit` y navegación de modelos
- Usa `odools.toml` para configuración de paths
- Comando: `Ctrl+Shift+P` → "Odoo: Reindex Addons" después de cambios

> **Nota:** La extensión oficial `odoo.odoo` puede causar conflictos. Deshabilitar para el workspace.

<details>
<summary><b>Configuraciones estilo PyCharm (productividad)</b></summary>

El archivo `.vscode/settings.json` incluye configuraciones para mejorar productividad:

**Límites de línea y formato:**

| Setting | Valor | Descripción |
|---------|-------|-------------|
| `editor.rulers` | `[88, 120]` | Guías visuales (Black: 88, Odoo: 120) |
| `[python].editor.formatOnSave` | `true` | Auto-formato al guardar |
| `[python].editor.defaultFormatter` | `autopep8` | Formateador por defecto |

**Navegación y contexto:**

| Setting | Valor | Descripción |
|---------|-------|-------------|
| `editor.stickyScroll.enabled` | `true` | Mantener clase/función visible |
| `breadcrumbs.enabled` | `true` | Ruta de navegación de código |
| `editor.minimap.enabled` | `true` | Vista previa del archivo |

**Colorización y guías:**

| Setting | Valor | Descripción |
|---------|-------|-------------|
| `editor.bracketPairColorization.enabled` | `true` | Colorear pares de paréntesis |
| `editor.guides.bracketPairs` | `active` | Resaltar par activo |
| `editor.guides.indentation` | `true` | Guías de indentación |

**Inlay hints (tipos y parámetros):**

| Setting | Valor | Descripción |
|---------|-------|-------------|
| `editor.inlayHints.enabled` | `onUnlessPressed` | Mostrar hints (Ctrl oculta) |
| `python.analysis.inlayHints.functionReturnTypes` | `true` | Tipos de retorno |
| `python.analysis.inlayHints.variableTypes` | `true` | Tipos de variables |

**Auto-guardado y limpieza:**

| Setting | Valor | Descripción |
|---------|-------|-------------|
| `files.autoSave` | `afterDelay` | Guardar automáticamente |
| `files.autoSaveDelay` | `1000` | Delay de 1 segundo |
| `files.trimTrailingWhitespace` | `true` | Eliminar espacios al final |

**Cursor y scrolling:**

| Setting | Valor | Descripción |
|---------|-------|-------------|
| `editor.smoothScrolling` | `true` | Scroll suave |
| `editor.cursorSmoothCaretAnimation` | `on` | Animación del cursor |
| `editor.renderLineHighlight` | `all` | Resaltar línea actual |

</details>

<details>
<summary><b>Auto-reindex de Odoo IDE al inicio</b></summary>

Para ejecutar reindex automáticamente al abrir el workspace:

1. Instalar extensión:
```bash
code --install-extension gabrielgrinberg.auto-run-command
```

2. Configuración ya incluida en `settings.json`:
```json
"auto-run-command.rules": [
    {
        "command": "odoo-ide.reindex",
        "message": "Reindexing Odoo addons..."
    }
]
```

</details>

**Variables de entorno para Claude Code:**

Configurar `ODOO_RC` según el cliente activo en `.vscode/settings.json`:

```json
"claudeCode.environmentVariables": [
    "ODOO_RC=${workspaceFolder}/config/<client>/dev.conf",
    "PYTHONPATH=${workspaceFolder}/odoo:${workspaceFolder}/odoo-enterprise",
    "LANG=es_PE.UTF-8",
    "TZ=America/Lima"
]
```

> Cambiar `<client>` por el nombre del cliente: `config/cliente1/dev.conf`, `config/cliente2/dev.conf`, etc.

**Copiar configuración por proyecto / cliente**
```bash
# Para desarrollo local
cp config/dev.conf.example config/<client>/dev.conf

# Para producción (opcional)
cp config/prod.conf.example config/<client>/prod.conf
```

**Archivos de configuración disponibles:**

| Archivo | Uso | Características |
|---------|-----|-----------------|
| `dev.conf.example` | Desarrollo local | workers=0 (debug), logging verbose, límites relajados |
| `prod.conf.example` | Producción | Multi-worker, logging mínimo, seguridad reforzada |

Se recomienda crear una carpeta por cada cliente / proyecto con sus respectivos archivos de configuración.

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
- wkhtmltopdf (versión según `ODOO_TAG` en `.env`)

**Versiones de wkhtmltopdf:**

| ODOO_TAG | wkhtmltox |
|----------|-----------|
| 14.0 - master | 0.12.6.1-3 |
| 12.0 - 13.0 | 0.12.5-1 |

**⚠️ Advertencia de seguridad para Python <3.12:**

Al seleccionar versiones de Python inferiores a 3.12, el script muestra una advertencia y requiere confirmación:

| CVE | Paquete | Severidad |
|-----|---------|-----------|
| CVE-2025-66471, CVE-2025-66418 | urllib3 | 🔴 High |
| CVE-2025-64512 | pdfminer.six | 🔴 High |
| CVE-2025-48994, CVE-2025-48995 | signxml | 🟡 Medium |
| CVE-2024-12797 | cryptography | 🟢 Low |

> **Recomendación:** Usar Python 3.12 o superior para entornos de producción.

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

<details>
<summary>Instalación de wkhtmltopdf</summary>

wkhtmltopdf es requerido por Odoo para generar reportes PDF. Odoo 14+ requiere la versión 0.12.6 con parches Qt.

```bash
# Ubuntu 22.04 (jammy) / amd64
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb
sudo dpkg -i wkhtmltox_0.12.6.1-3.jammy_amd64.deb
sudo apt-get install -f -y

# Ubuntu 24.04 (noble) - usar paquete de jammy
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb
sudo dpkg -i wkhtmltox_0.12.6.1-3.jammy_amd64.deb
sudo apt-get install -f -y

# Verificar instalación
wkhtmltopdf --version
```

> **Nota:** Para otras distribuciones, consulta [wkhtmltopdf releases](https://github.com/wkhtmltopdf/packaging/releases).
</details>

# Clonar repositorios de Odoo

El script `clone-addons.sh` clona los repositorios de Odoo Community, Enterprise y Themes desde los forks de focuz-ai.

```bash
chmod +x clone-addons.sh
./clone-addons.sh
```

**Opciones disponibles:**

| Opción | Descripción |
|--------|-------------|
| `-s, --sync` | Sincronizar forks con upstream Odoo (fetch, merge, push) |
| `-h, --help` | Mostrar ayuda del script |

**Ejemplos:**
```bash
./clone-addons.sh              # Solo clonar repositorios
./clone-addons.sh --sync       # Clonar y sincronizar con upstream Odoo
./clone-addons.sh --help       # Mostrar ayuda
```

**Repositorios clonados:**

| Carpeta local | Fork (focuz-ai) | Upstream (Odoo) |
|---------------|-----------------|-----------------|
| `odoo/` | focuz-ai/odoo | odoo/odoo |
| `odoo-enterprise/` | focuz-ai/odoo-enterprise | odoo/enterprise |
| `odoo-themes/` | focuz-ai/odoo-design-themes | odoo/design-themes |

> **Nota:** La opción `--sync` requiere credenciales de GitHub configuradas en `.env` (GITHUB_USER y GITHUB_ACCESS_TOKEN).

# Crear entorno virtual e instalar dependencias

## Odoo 16 con Python 3.12 (Recomendado)

**Python 3.12** es la versión recomendada para Odoo 16. Evita problemas de compatibilidad con gevent/Cython que ocurren con Python 3.10.

```bash
# Crear entorno virtual con Python 3.12
python3.12 -m venv .venv
source .venv/bin/activate

# Instalar dependencias
pip install --upgrade pip setuptools wheel
pip install -r odoo/requirements.txt
pip install -r requirements.txt

# Verificar instalación
pip check
```

**Versiones clave instaladas:**
| Paquete | Versión | Nota |
|---------|---------|------|
| gevent | 24.2.1 | Compatible con Python 3.12 |
| greenlet | 3.0.3 | Compatible con Python 3.12 |
| Werkzeug | 2.0.2 | Requerido por Odoo 16 (3.x no compatible) |

<details>
<summary><b>Alternativa: Python 3.10 (solo si es requerido)</b></summary>

Python 3.10 tiene problemas con setuptools/Cython modernos que no compilan gevent 21.8.0.

**Error típico:**
```
Error compiling Cython file: src/gevent/libev/corecext.pyx:60:26: undeclared name not builtin: long
ERROR: Failed to build 'gevent' when getting requirements to build wheel
```

**Solución:** Usar `setuptools<70` y `Cython<3` con `--no-build-isolation`:

```bash
python3.10 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install "setuptools<70" wheel "Cython<3"
pip install -r odoo/requirements.txt --no-build-isolation
pip install -r requirements.txt
pip check
```

</details>

## Odoo 17+ con Python 3.13

Para Odoo 17 o superior, usar Python 3.13 con instalación estándar:

```bash
python3.13 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r odoo/requirements.txt
pip install -r requirements.txt
```

## Desactivar entorno virtual

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

## InterfaceError: connection already closed

Este error ocurre al editar código Python mientras Odoo está corriendo con `--dev=all`:

```
psycopg2.InterfaceError: connection already closed
  File "odoo/service/server.py", line 507, in _run_cron
    pg_conn.poll()
```

**Causa:** Cuando `max_cron_threads > 0` y se usa auto-reload (`--dev=all`), el hilo de cron mantiene conexiones PostgreSQL que se cierran abruptamente al recargar el servidor.

**Solución:** Deshabilitar cron en desarrollo:

```ini
# En config/<client>/dev.conf
max_cron_threads = 0
```

> **Nota:** Si necesitas probar cron jobs, usa `max_cron_threads = 1` pero sin `--dev=all`.

## OSError: [Errno 24] inotify instance limit reached

```bash
sudo nano /etc/sysctl.conf
fs.inotify.max_user_instances = 1100000
sudo sysctl -p
```

# Coding Guidelines

Seguimos las [Odoo Coding Guidelines](https://www.odoo.com/documentation/master/contributing/development/coding_guidelines.html) oficiales. Consulta [CLAUDE.md](CLAUDE.md) para guías detalladas.

## Estructura de Modelos

```python
class MyModel(models.Model):
    # 1. Atributos privados (_name, _description, _inherit, _order)
    # 2. Métodos default
    # 3. Campos
    # 4. SQL constraints
    # 5. Compute/inverse/search
    # 6. Selection methods
    # 7. Constraints y onchange
    # 8. CRUD overrides
    # 9. Action methods
    # 10. Business methods
```

## Convenciones de Nombres

| Elemento | Convención | Ejemplo |
|----------|------------|---------|
| Modelo | Singular, dot notation | `sale.order` |
| Campo Many2one | Sufijo `_id` | `partner_id` |
| Campo X2many | Sufijo `_ids` | `line_ids` |
| Método compute | `_compute_<field>` | `_compute_total` |
| Método action | `action_<verb>` | `action_confirm` |

## Reglas Críticas

```python
# ❌ NUNCA hacer commit manual
self.env.cr.commit()  # PROHIBIDO

# ❌ No usar _() en Selection de clase
state = fields.Selection([('draft', _('Draft'))])  # MAL

# ✅ Selection sin _()
state = fields.Selection([('draft', 'Draft')])  # BIEN

# ✅ Usar @api.model_create_multi (Odoo 16+)
@api.model_create_multi
def create(self, vals_list):
    return super().create(vals_list)
```

## Estructura de Módulo

```
my_module/
├── __init__.py
├── __manifest__.py
├── models/          # Un archivo por modelo
├── views/           # <modelo>_views.xml
├── security/        # ir.model.access.csv, *_groups.xml
├── wizard/          # Transient models
├── data/            # *_data.xml, *_demo.xml
└── static/src/      # js/, scss/, xml/
```

# Contribuir a Odoo

Este proyecto usa forks de Odoo para facilitar contribuciones upstream. Seguimos las [Odoo Git Guidelines](https://www.odoo.com/documentation/master/contributing/development/git_guidelines.html).

## Formato de Commits

```
[TAG] module: descripción corta (< 50 chars)

Descripción larga explicando POR QUÉ se hizo el cambio,
incluyendo razonamiento y decisiones técnicas.

References: task-123, Fixes #123
```

## Tags Disponibles

| Tag | Uso |
|-----|-----|
| `[FIX]` | Bug fixes |
| `[IMP]` | Mejoras incrementales |
| `[ADD]` | Nuevos módulos |
| `[REF]` | Refactoring |
| `[REM]` | Eliminar código muerto |
| `[REV]` | Revertir commits |
| `[MOV]` | Mover archivos |
| `[I18N]` | Traducciones |
| `[PERF]` | Performance |
| `[CLN]` | Limpieza de código |

## Workflow para Contribuir

```bash
# 1. Configurar remotes (si no están)
cd odoo
git remote add upstream https://github.com/odoo/odoo.git

# 2. Actualizar desde upstream
git fetch upstream master

# 3. Crear branch para el fix/feature
git checkout -b master-fix-descripcion upstream/master

# 4. Hacer cambios y commit
git add .
git commit -m "[FIX] module: descripción corta

Descripción larga del por qué..."

# 5. Push al fork
git push origin master-fix-descripcion

# 6. Crear PR en GitHub
gh pr create --repo odoo/odoo --base master \
  --head focuz-ai:master-fix-descripcion \
  --title "[FIX] module: descripción corta"
```

## Firmar el CLA

Antes de contribuir, debes firmar el [Odoo CLA](https://github.com/odoo/odoo/blob/master/doc/cla/sign-cla.md):

1. Crear archivo en `odoo/doc/cla/individual/<github_username>.md`
2. Seguir el formato de los archivos existentes
3. Crear PR con tag `[CLA]`

## Sincronizar Fork con Upstream

```bash
# Usando el script incluido
./clone-addons.sh --sync

# O manualmente
cd odoo
git fetch upstream
git checkout master
git merge upstream/master
git push origin master
```

# Documentación adicional

Por favor, consulte la [sección de documentos](https://github.com/focuzai/odoo_vsc/tree/main/docs).

Para guías detalladas de desarrollo, consulte [CLAUDE.md](CLAUDE.md).

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