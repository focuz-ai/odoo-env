# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Odoo 19 development environment (o19-env) configured for multi-client/multi-project development with VSCode
integration. It supports Odoo Community, Enterprise, and custom modules with a focus on Peruvian localization (l10n_pe).

## Repository Structure

```
o19-env/
├── odoo/              # Odoo Community (clon de odoo/odoo — no editar)
├── enterprise/        # Odoo Enterprise (clon de odoo/enterprise — no editar)
├── design-themes/     # Odoo Themes (clon de odoo/design-themes — no editar)
├── config/            # Configs por cliente (dev.conf, prod.conf)
│   └── <client>/      # l10n-pe, alimts, hanoi, ETL, odoo, …
├── src/
│   ├── dev/
│   │   └── focuz-ai/  # Repos compartidos (ver tabla abajo)
│   ├── projects/      # Addons por cliente
│   │   └── <client>/{dev,main,temp}/
│   └── migrate/       # Migraciones (excluido del IDE; histórico)
├── vendor/            # Third-party addons (OCA, etc.)
├── scripts/           # DB template/clone, filestore cleanup, utilidades
├── openspec/          # OpenSpec (workflow spec-driven)
├── .claude/           # Skills/comandos OpenSpec para agentes
├── docs/              # Estándares de desarrollo + guías del entorno
└── .venv/             # Python 3.12 virtual environment (active)

# Fuera del workspace (convención o19-offsite/ — ver sección Odoo IDE):
../o19-offsite/industry/   # Industry modules (runtime vía addons_path en dev.conf)
```

### Repos `src/dev/focuz-ai/`

| Carpeta       | Contenido típico                        |
| ------------- | --------------------------------------- |
| `l10n-pe`     | Localización peruana (EDI, PLE, nómina) |
| `enterprise`  | Módulos EE propios (focuz-ai)           |
| `etl`         | Integraciones ETL                       |
| `ifrs`        | IFRS / reportes                         |
| `misc`        | Utilidades varias                       |
| `odoo-oca`    | Submódulos OCA (purchase, stock, …)     |
| `odoo-vendor` | Addons de terceros propios              |
| `ssoma`       | SSOMA / seguridad ocupacional           |

### Mapa rápido: "¿Dónde tocar para...?"

| Intención                             | Archivo / directorio                                              |
| ------------------------------------- | ----------------------------------------------------------------- |
| Agregar una config de cliente         | `config/<client>/{dev,prod}.conf` (copiar de `*.example`)         |
| Agregar un addons-path para el IDE    | `pyrightconfig.json` (`extraPaths`) — `odools.toml` está obsoleto |
| Agregar un repo a clonar              | `clone-addons.txt`                                                |
| Run/debug Odoo desde VSCode           | `.vscode/launch.json` (copiar de `.example`)                      |
| Configuración de linter               | `ruff.toml` + `pyproject.toml` (`[tool.pyright]`, `[tool.mypy]`)  |
| Pre-commit hooks                      | `.pre-commit-config.yaml`                                         |
| Addons internos por cliente           | `src/projects/<client>/{dev,main,temp}/`                          |
| Addons internos compartidos           | `src/dev/focuz-ai/<repo>/`                                        |
| Scripts operacionales (DB, filestore) | `scripts/`                                                        |
| Estándares de código Odoo             | `docs/` (convenciones, ORM, seguridad, tests, git)                |
| Optimización del entorno (uv, DB, PG) | `docs/dev-environment-optimization.md`                            |
| Gestión de submódulos git             | `docs/submodule.md`                                               |
| Workflow spec-driven (OpenSpec)       | `openspec/` + `.claude/skills/openspec-*`                         |

## Python Environment

**Python 3.12** (versión activa del `.venv`, default del `setup_env.sh`)

```bash
# Activate virtual environment
source .venv/bin/activate
python --version   # → Python 3.12.x
```

### Python Version Compatibility

| Python | Status        | Notes                                           |
| ------ | ------------- | ----------------------------------------------- |
| 3.10   | ✅ Supported  | Minimum version                                 |
| 3.11   | ✅ Supported  | Legacy stable                                   |
| 3.12   | ✅ **Active** | Versión del `.venv` y default de `setup_env.sh` |
| 3.13   | ✅ Supported  | Disponible vía `setup_env.sh -p 3.13`           |
| 3.14   | ✅ Supported  | Disponible vía `setup_env.sh -p 3.14`           |

## Development Commands

```bash
# Activate virtual environment
source .venv/bin/activate

# Run Odoo with config file
python odoo/odoo-bin -c config/<client>/dev.conf

# Install module
python odoo/odoo-bin -c config/<client>/dev.conf -d <database> -i <module_name>

# Update module
python odoo/odoo-bin -c config/<client>/dev.conf -d <database> -u <module_name>

# Run tests for a module
python odoo/odoo-bin -c config/<client>/dev.conf -d <database> --test-enable -i <module_name> --stop-after-init

# Odoo shell
python odoo/odoo-bin shell -d <database> -c config/<client>/dev.conf

# Odoo shell with IPython
python odoo/odoo-bin shell -d <database> -c config/<client>/dev.conf --xmlrpc-port 8888 --gevent-port 8899 --shell-interface ipython

# Scaffold new module
python odoo/odoo-bin scaffold <module_name> src/dev/<organization>/

# Development mode with auto-reload
python odoo/odoo-bin -c config/<client>/dev.conf --dev=all
```

## Dependencies Installation

**Order matters**: Install Odoo requirements first to lock base versions.

> **Recomendado: usa `uv`** — drop-in replacement de pip, 10-100x más rápido. Ver
> [docs/dev-environment-optimization.md](docs/dev-environment-optimization.md).

```bash
# 1. Activate environment
source .venv/bin/activate

# 2. Install uv (una sola vez)
pip install uv

# 3. Install Odoo dependencies first (locks cryptography, Pillow, lxml, etc.)
uv pip install -r odoo/requirements.txt

# 4. Install project dependencies (respects Odoo versions)
uv pip install -r requirements.txt

# 5. Verify no conflicts
uv pip check
```

> Si prefieres pip clásico, sustituye `uv pip` por `pip` en los pasos 3-5.

### Key Library Versions by Python

| Library      | Python 3.10-3.11 | Python 3.12+     | Security Notes                         |
| ------------ | ---------------- | ---------------- | -------------------------------------- |
| cryptography | 3.4.8 ⚠️         | ≥44.0.1 ✅       | CVE-2024-12797 fixed in 44.0.1         |
| urllib3      | 1.26.19 ⚠️       | ≥2.6.0 ✅        | CVE-2025-66471/66418 fixed in 2.6.0    |
| pdfminer.six | 20211012 ⚠️      | ≥20251230 ✅     | CVE-2025-64512 fixed; pickle vuln open |
| signxml      | 3.1.1 ⚠️         | ≥4.0.4 ✅        | CVE-2025-48994/48995 fixed in 4.0.4    |
| Pillow       | 9.0.1 / 9.4.0    | ≥10.3.0 / 11.1.0 | CVE-2024-28219 fixed                   |
| pandas       | 1.3.5            | ≥2.2.3           | -                                      |
| numpy        | 1.26.x           | 1.26.x / 2.4.x+  | -                                      |
| PyArrow      | 15.x             | 15.x / 18.x+     | -                                      |

> ⚠️ = Vulnerable (Odoo constraints prevent update) | ✅ = Patched

## Configuration Files

- **`.env`**: Environment variables (ODOO_TAG, GITHUB_USER, GITHUB_ACCESS_TOKEN)
- **`pyrightconfig.json`**: Scope y addons-paths del Odoo IDE (Pyright). Reemplaza a `odools.toml`, que quedó obsoleto
  en Odoo IDE ≥ 0.40 (ver "Límite de indexación del Odoo IDE")
- **`odools.toml`**: ⚠️ Obsoleto — solo compatibilidad con entornos antiguos (o16/o17/o18)
- **`config/<client>/<branch>.conf`**: Odoo configuration per client/branch (clientes activos: `l10n-pe`, `alimts`,
  `hanoi`, `ETL`, `odoo`)
- **`clone-addons.txt`**: Controls which repositories to clone via `clone-addons.sh`

## Initial Setup

```bash
# Clone and configure
git clone -b 19.0 git@github.com:focuz-ai/odoo-env.git o19-env
cd o19-env
cp .env.example .env
cp odools.toml.example odools.toml   # opcional/obsoleto: Odoo IDE ≥0.40 usa pyrightconfig.json
cp config/dev.conf.example config/<client>/dev.conf
# Para producción:
# cp config/prod.conf.example config/<client>/prod.conf
cp .vscode/launch.json.example .vscode/launch.json

# Clone Odoo repositories
./clone-addons.sh

# Create Python 3.12 virtual environment
python3.12 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install --upgrade pip setuptools wheel
pip install -r odoo/requirements.txt
pip install -r requirements.txt
pip check

# Editor tooling (Prettier format-on-save)
npm ci
pre-commit install
```

## Setup Environment Script

The `setup_env.sh` script prepares the development environment automatically.

### Usage

```bash
./setup_env.sh                  # Install with Python 3.12 (default)
./setup_env.sh -p 3.13          # Install with Python 3.13
./setup_env.sh --help           # Show help
```

### What it installs

| Component         | Description                                                      |
| ----------------- | ---------------------------------------------------------------- |
| Python            | Specified version (3.10-3.14) + pip + venv                       |
| Odoo dependencies | Build tools, libraries (libsasl2, libldap2, libcairo2-dev, etc.) |
| PostgreSQL client | psql command-line tool                                           |
| wkhtmltopdf       | PDF generation for Odoo reports                                  |

### wkhtmltopdf Version Selection

The script automatically selects the correct wkhtmltopdf version based on `ODOO_TAG` in `.env`:

| ODOO_TAG    | wkhtmltox Version |
| ----------- | ----------------- |
| 14.0 - 19.0 | 0.12.6.1-3        |
| 12.0 - 13.0 | 0.12.5-1          |

The script handles fallback for distributions without official packages (e.g., noble → jammy).

### Security Warning for Python <3.12

When selecting Python versions below 3.12, the script displays a security warning and requires confirmation:

| CVE                            | Package      | Severity | Reason                    |
| ------------------------------ | ------------ | -------- | ------------------------- |
| CVE-2025-66471, CVE-2025-66418 | urllib3      | High     | Requires urllib3 1.x      |
| CVE-2024-12797                 | cryptography | Low      | Requires cryptography 3.x |
| CVE-2025-48994, CVE-2025-48995 | signxml      | Medium   | Requires lxml 4.x         |
| CVE-2025-64512                 | pdfminer.six | High     | Requires cryptography 3.x |

These vulnerabilities cannot be patched in Python <3.12 due to Odoo's dependency constraints.

**Recommendation:** Use Python 3.12 or higher for security-critical deployments.

## Clone Addons Script

The `clone-addons.sh` script clones Odoo repositories and optionally syncs focuz-ai forks with upstream Odoo.

### Usage

```bash
# Show help
./clone-addons.sh --help

# Clone repositories only (default)
./clone-addons.sh

# Clone and sync with upstream Odoo
./clone-addons.sh --sync
```

### Options

| Option       | Description                                                 |
| ------------ | ----------------------------------------------------------- |
| `-s, --sync` | Sync focuz-ai forks with upstream Odoo (fetch, merge, push) |
| `-h, --help` | Show help message                                           |

### Repositories Managed

Por defecto `clone-addons.txt` clona **directamente desde upstream Odoo** (rama `ODOO_TAG` del `.env`):

| Local Folder     | Origen (clone)                | Upstream (sync `--sync`) |
| ---------------- | ----------------------------- | ------------------------ |
| `odoo/`          | github.com/odoo/odoo          | odoo/odoo                |
| `enterprise/`    | github.com/odoo/enterprise    | odoo/enterprise          |
| `design-themes/` | github.com/odoo/design-themes | odoo/design-themes       |

Enterprise requiere `ENTERPRISE_USER` / `ENTERPRISE_ACCESS_TOKEN` en `.env`.

### Sync Functionality (--sync)

Opcional: sincroniza el `origin` del clone local con upstream Odoo y hace push (útil si `origin` apunta a un fork
focuz-ai):

1. Añade remote `upstream` si no existe
2. Fetch de la rama `ODOO_TAG` desde upstream
3. Merge (o crea la rama desde upstream si falta en origin)
4. Push a `origin` (requiere `GITHUB_USER` / `GITHUB_ACCESS_TOKEN`)

### Requirements

Configure `.env` with GitHub credentials for private repos and sync:

```bash
GITHUB_USER=your_username
GITHUB_ACCESS_TOKEN=ghp_your_token
```

### Configuration (clone-addons.txt)

```bash
# Format: <type> <repo_url> <condition>
public https://github.com/odoo/odoo true
themes https://github.com/odoo/design-themes true
enterprise https://github.com/odoo/enterprise true
```

## Database Configuration

Default PostgreSQL settings:

- Host: 127.0.0.1
- Port: 5435 (non-standard to avoid conflicts)
- User: odoo
- Password: odoo

## Database Workflow Scripts (`scripts/`)

Scripts en `scripts/` para acelerar el ciclo "DB limpia con módulos pre-instalados". Todos leen credenciales del `.conf`
que les pases (default `config/l10n-pe/dev.conf`).

| Script                                                   | Qué hace                                                                                                                                                                                                                                         |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `scripts/db-template-create.sh [TPL] [MODULES] [CONFIG]` | Crea un template Postgres con módulos pre-instalados (ej. `tpl_l10n_pe` con `base,web,l10n_pe`). Marca la DB como `datistemplate=true` y bloquea conexiones. Lento la primera vez.                                                               |
| `scripts/db-clone-from-template.sh TPL NEW_DB [CONFIG]`  | Clona una DB fresca desde el template en segundos (`CREATE DATABASE … TEMPLATE …`). Idempotente: si `NEW_DB` ya existe, la elimina primero.                                                                                                      |
| `scripts/clean-orphan-filestores.sh [--apply]`           | Detecta filestores en `~/.local/share/Odoo/filestore/` cuya DB ya no existe en **ninguna** instancia Postgres conocida. Dry-run por defecto; `--apply` borra. Soporta multi-instancia vía `--instances-glob` o `--instance HOST:PORT:USER:PASS`. |

**Workflow recomendado:**

```bash
# 1. Una sola vez (lento): seed un template con los módulos que reúsas
./scripts/db-template-create.sh tpl_l10n_pe base,web,l10n_pe

# 2. Repetido (~segundos): clonar DBs frescas para tests aislados
./scripts/db-clone-from-template.sh tpl_l10n_pe pe_test_$(date +%Y%m%d)

# 3. Periódicamente: liberar disco eliminando filestores huérfanos
./scripts/clean-orphan-filestores.sh           # listar (dry-run)
./scripts/clean-orphan-filestores.sh --apply   # borrar
```

## Linting & Pre-commit

El repo ships con `.pre-commit-config.yaml` (Ruff v0.15.12 + ruff-format + OCA `pylint-odoo` v10) y excluye
automáticamente `odoo/`, `enterprise/`, `design-themes/`, `industry/`, `vendor/`, `.venv/` y `migrations/`.

### Format-on-save (editor)

Abre siempre el workspace **`o19-env`** (`o19-env.code-workspace` o la carpeta raíz), **no un subrepo suelto**
(`odoo-enterprise`, `odoo-l10n-pe`, …). La config vive en `.vscode/settings.json` del env.

| Tipo de archivo                      | Formateador al guardar | Extensión                |
| ------------------------------------ | ---------------------- | ------------------------ |
| Python (`.py`)                       | Ruff                   | `charliermarsh.ruff`     |
| Markdown, XML, YAML, JSON, CSS, HTML | Prettier               | `esbenp.prettier-vscode` |

**Setup (una sola vez, desde la raíz de `o19-env`):**

```bash
npm ci                        # Prettier + @prettier/plugin-xml en node_modules/
pre-commit install            # hooks al commitear (validan lo mismo que CI)
```

**Settings clave** (`.vscode/settings.json` / `o19-env.code-workspace`):

| Setting                          | Valor                   | Notas                                                                                           |
| -------------------------------- | ----------------------- | ----------------------------------------------------------------------------------------------- |
| `prettier.prettierPath`          | `node_modules/prettier` | **Módulo**, no `…/bin/prettier.cjs` (la extensión falla con el binario)                         |
| `prettier.configPath`            | `prettier.config.cjs`   | Ruta **relativa** al workspace; **no** uses `${workspaceFolder}/…` (la extensión no lo expande) |
| `prettier.requireConfig`         | `false`                 |                                                                                                 |
| `editor.formatOnSaveMode`        | `file`                  | No `modifications` (Prettier no formatea bien Markdown en modo parcial)                         |
| `[markdown].editor.formatOnSave` | `true`                  | Igual para `[xml]`, `[yaml]`, `[json]`                                                          |

**Manual** (mismo Prettier que el editor):

```bash
npm run format:file -- src/dev/focuz-ai/enterprise/CLAUDE.md
npm run format:file -- path/to/file.md
```

**Hook vs CI:** `pre-commit install` corre al **`git commit`** (y aborta si reescribe archivos — vuelve a `git add` y
commitea). **CI** ejecuta los mismos hooks pero **nunca commitea** el fix; por eso un push puede fallar si no pasaste
pre-commit localmente. Prettier en CI también valida vía pre-commit, no vía format-on-save.

**Troubleshooting:** _Output → Prettier_. Errores típicos ya corregidos en settings: `prettierPath` apuntando al
binario; `configPath` con `${workspaceFolder}` literal en la ruta.

```bash
# Sobre archivos staged (default, rápido)
pre-commit run

# Sobre archivos específicos
pre-commit run --files src/dev/focuz-ai/<repo>/<module>/models/<file>.py

# Ruff directo (linter + formatter)
ruff check .                  # lint
ruff check --fix .            # autofix
ruff format .                 # format
```

**Configuración relevante:**

- `prettier.config.cjs` + `package.json` en la raíz del env (compartido por todos los addons en `src/dev/` y
  `src/projects/`).
- `ruff.toml`: `line-length=120`, reglas activas `E,F,B,SIM`, ignora `F401` en `__init__.py` y `B018` en
  `__manifest__.py`.
- `pyproject.toml`: configuración de Pyright/Mypy (Mypy deshabilitado en práctica — Odoo no tiene type stubs).

> **Nota:** No correr `pre-commit run --all-files` en la primera pasada — incluye archivos del repo que no han pasado
> por la convención y genera mucho ruido. Usar siempre staged o `--files`.

## Odoo Coding & Git Guidelines

Los estándares de desarrollo (coding guidelines, ORM/rendimiento, seguridad, OWL/SCSS, testing) y las git guidelines
viven ahora en **[`docs/`](docs/README.md)** — única fuente de verdad, estandarizada con la plantilla del sistema
`odoo-openspec`:

| Tema                                                                                      | Documento                                                                    |
| ----------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Convenciones, estructura de módulo, orden de atributos, naming, XML, SCSS, i18n, permisos | [docs/conventions.md](docs/conventions.md)                                   |
| ORM, N+1, computes, índices, SQL, transacciones/savepoints, excepciones                   | [docs/orm-performance.md](docs/orm-performance.md)                           |
| ACL/CSV, grupos, record rules, sudo, multi-compañía, controladores                        | [docs/security.md](docs/security.md)                                         |
| OWL 2, QWeb-JS, assets/registry, widgets, SCSS, tests del web client                      | [docs/frontend-owl.md](docs/frontend-owl.md)                                 |
| TransactionCase/HttpCase + framework JS de la versión, trazabilidad, upgrade-safety       | [docs/testing.md](docs/testing.md)                                           |
| Formato de commit, tags, ramas, PR (estilo Odoo)                                          | [docs/git-guidelines.md](docs/git-guidelines.md)                             |
| Optimización del entorno (uv, Postgres dev, templates DB, VSCode)                         | [docs/dev-environment-optimization.md](docs/dev-environment-optimization.md) |
| Gestión de submódulos git (operativo)                                                     | [docs/submodule.md](docs/submodule.md)                                       |

> Los agentes IA del flujo resuelven `docs/<tema>.md` contra este `docs/` (estándar de la versión activa). El resto de
> este `CLAUDE.md` cubre el **entorno** (Python, deps, IDE, etc.), no el código del módulo.

## OpenSpec (workflow spec-driven)

El repo incluye scaffolding OpenSpec en `openspec/` (`config.yaml`, schema `spec-driven`) y skills en `.claude/skills/`:

| Skill / comando           | Uso                                               |
| ------------------------- | ------------------------------------------------- |
| `openspec-propose`        | Generar propuesta completa (design, specs, tasks) |
| `openspec-apply-change`   | Implementar tareas de un cambio                   |
| `openspec-explore`        | Modo exploración / clarificación de requisitos    |
| `openspec-archive-change` | Archivar un cambio completado                     |

Comandos slash en `.claude/commands/opsx/` (`propose`, `apply`, `explore`, `archive`).

## Git Submodule Management

El superproyecto `o19-env` **no** usa `.gitmodules` en la raíz. Los repos en `src/dev/focuz-ai/` son repositorios git
independientes; algunos (p. ej. `odoo-oca`) sí contienen submódulos OCA anidados. Guía operativa completa:
**[docs/submodule.md](docs/submodule.md)**.

```bash
# Dentro de un repo con submódulos (ej. src/dev/focuz-ai/odoo-oca/)
git submodule update --init --recursive
git submodule update --remote --merge          # actualizar a última de la rama trackeada

# Tras pull que cambió referencias de submódulos
git pull --recurse-submodules
```

## VSCode Integration

Launch configurations in `.vscode/launch.json`:

| Configuration           | Description                 | Key Args                         |
| ----------------------- | --------------------------- | -------------------------------- |
| `Odoo: Development`     | Run server with hot reload  | `--dev=all`                      |
| `Odoo: Install Module`  | Install module and exit     | `-i <module> --stop-after-init`  |
| `Odoo: Update Module`   | Update module and exit      | `-u <module> --stop-after-init`  |
| `Odoo: Run Tests`       | Run module tests            | `--test-enable --log-level=test` |
| `Odoo: Shell (IPython)` | Interactive shell           | `--shell-interface ipython`      |
| `Odoo: Scaffold Module` | Create new module structure | `scaffold <name> src/dev/`       |

All configurations use debugpy with `frozen_modules=off` for debugging support.

### Launch Setup

```bash
cp .vscode/launch.json.example .vscode/launch.json
# Edit launch.json: replace <database> and <module_name> placeholders
```

### Workspace Settings (`.vscode/settings.json`)

| Setting                            | Value                      | Purpose                                           |
| ---------------------------------- | -------------------------- | ------------------------------------------------- |
| `python.languageServer`            | `"None"`                   | Pylance deshabilitado (Odoo IDE usa Pyright)      |
| `odoo.selectedProfile`             | `""`                       | Deshabilita extensión oficial Odoo                |
| `python.analysis.typeCheckingMode` | `"basic"`                  | Recomendado por Odoo IDE                          |
| `python.analysis.diagnosticMode`   | `"openFilesOnly"`          | Solo archivos abiertos                            |
| `python.analysis.extraPaths`       | `[odoo, odoo/addons, ...]` | Paths para resolver imports                       |
| `editor.quickSuggestions.strings`  | `"on"`                     | Autocompletado en strings (XML IDs)               |
| `files.watcherInclude`             | `["**"]`                   | Detectar cambios en symbolic links                |
| `files.watcherExclude`             | `enterprise`, `.venv`, …   | Reducir CPU del file watcher (no afecta Odoo IDE) |
| `search.exclude`                   | `enterprise`, `vendor`, …  | Excluir vendored del search global                |

### Odoo IDE como Language Server

**Configuración actual:** Odoo IDE es el único Language Server activo:

- **Pylance:** Deshabilitado (no interpreta bien los tipos de Odoo)
- **Odoo IDE:** Resolución de modelos, `_inherit`, fields, XML IDs
- **Mypy:** Deshabilitado (conflicto con Odoo, sin type stubs)

**⚠️ IMPORTANTE:** Si tienes **Pyright standalone** (`ms-pyright.pyright`) instalada, deshabilitarla:

```
1. Ctrl+Shift+X (Extensions)
2. Buscar "Pyright"
3. Click en engranaje (⚙️)
4. Seleccionar "Disable (Workspace)"
```

**Síntomas de conflicto:**

```
Module "odoo" has no attribute "models"
Library stubs not installed for "dateutil"
```

### Configuración Pyright (`pyrightconfig.json`)

**Arquitectura de configuración:**

- **`pyrightconfig.json`:** Config que **carga el Odoo IDE** (su Pyright interno). Es la fuente de verdad del scope
  (`include`/`exclude`) y de `extraPaths`.
- **`settings.json` (`python.analysis.*`):** Respaldo para Pylance (deshabilitado).
- **`pyproject.toml [tool.pyright]`:** Fallback si se borra `pyrightconfig.json` (Pyright prioriza `pyrightconfig.json`
  cuando existe).

> El `include` se mantiene **acotado** y se excluyen árboles que no aportan a la resolución (`**/i18n`, `**/static/lib`,
> `src/migrate`, `documentation`, `industry`, `_tmp`, `reports`) para aligerar el análisis. Nota: ese `exclude` SÍ
> aplica al análisis de tipos, pero **NO** al gate de conteo del indexador (ver "Límite de indexación del Odoo IDE").

> Al añadir un repo nuevo en `src/dev/focuz-ai/`, agregar su path a `extraPaths` en **`pyrightconfig.json`** y reindexar
> Odoo IDE. `settings.json` (`python.analysis.extraPaths`) es respaldo parcial — puede quedar desfasado.

```json
{
  "include": ["odoo", "enterprise", "design-themes", "vendor/OCA", "src/dev", "src/projects"],
  "exclude": [
    "**/node_modules",
    "**/__pycache__",
    "**/.*",
    "**/i18n",
    "**/static/lib",
    "src/migrate",
    "documentation",
    "industry",
    "_tmp",
    "reports"
  ],
  "extraPaths": [
    "odoo",
    "odoo/addons",
    "enterprise",
    "design-themes",
    "vendor/OCA",
    "src/dev/focuz-ai/l10n-pe",
    "src/dev/focuz-ai/enterprise",
    "src/dev/focuz-ai/odoo-oca",
    "src/dev/focuz-ai/etl",
    "src/dev/focuz-ai/ifrs",
    "src/dev/focuz-ai/misc",
    "src/dev/focuz-ai/ssoma"
  ],
  "venvPath": ".",
  "venv": ".venv",
  "typeCheckingMode": "basic",
  "pythonVersion": "3.12",
  "reportMissingTypeStubs": false,
  "reportMissingModuleSource": false
}
```

| Diagnóstico                 | Razón para ignorar                   |
| --------------------------- | ------------------------------------ |
| `reportMissingTypeStubs`    | dateutil, lxml, etc. sin stubs       |
| `reportMissingModuleSource` | Módulos Odoo dinámicos               |
| `reportUnknownMemberType`   | Campos `self.field_name` dinámicos   |
| `reportUnknownArgumentType` | Argumentos dinámicos en métodos Odoo |

**Extensión requerida:** [Odoo IDE](https://marketplace.visualstudio.com/items?itemName=trinhanhngoc.vscode-odoo)

- Resolución de `_inherit` y navegación de modelos
- Autocompletado de campos y métodos
- Descubre los addons indexando los `__manifest__.py` del workspace

> ⚠️ **`odools.toml` quedó OBSOLETO.** Las versiones de Odoo IDE **≥ 0.40** (la instalada es 0.50.0) **ya no leen
> `odools.toml`** — son Pyright puro. La config de paths vive ahora en **`pyrightconfig.json`** (que el LSP carga al
> arrancar) y, como respaldo de Pylance, en `python.analysis.extraPaths` de `settings.json`. El archivo `odools.toml` se
> conserva solo por compatibilidad con entornos antiguos (o16/o17/o18) y no tiene efecto en este repo.

**Comandos útiles de Odoo IDE:**

- `Ctrl+Shift+P` → "Odoo IDE: Reindex" - Reindexar después de cambios de config
- `Ctrl+Shift+P` → "Developer: Reload Window" - Recargar el LSP (re-lee `pyrightconfig.json`)

> **Nota:** La extensión oficial `odoo.odoo` puede causar conflictos. Deshabilitar para el workspace si hay problemas.

#### ⚠️ Límite de indexación del Odoo IDE (>150k archivos)

El indexador del Odoo IDE (Pyright interno) tiene un **límite hardcodeado de 150.498 archivos** en el workspace. Si se
supera, **aborta TODA la indexación** (`BG: ... too many files for indexing` → `0 new files was indexed`) y deja de
resolver `.py`, `.xml` y modelos (síntoma típico: _"Could not find model 'ir.ui.view'"_).

**Importante:** ese gate **ignora el `exclude` de `pyrightconfig.json`** — camina el workspace entero saltando solo
`.git`/dot-dirs, `__pycache__` y `node_modules` (e **incluye `.venv`** a propósito). La única forma de bajar del límite
es **reducir archivos físicos** del workspace.

**Convención `o19-offsite/`:** los árboles pesados que NO se desarrollan se reubican fuera del workspace, en
`../o19-offsite/`, para no contar contra el límite:

| Reubicado           | Por qué                                                              | Runtime                                                                        |
| ------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `industry/`         | módulos vendored, no se editan                                       | el `addons_path` de los `config/*/dev.conf` apunta a `../o19-offsite/industry` |
| `documentation/`    | clon desechable de docs de Odoo (untracked)                          | sin uso en runtime                                                             |
| `src/migrate/<ver>` | código de versiones viejas (GM v18, ADR-019); `.gitkeep` se conserva | sin uso en runtime; referencia histórica                                       |

Diagnóstico rápido del conteo y del log:

```bash
# Conteo real que ve el gate (replica su lógica: incluye .venv, salta dot-dirs)
find . -type f -not -path '*/.git/*' -not -path '*/__pycache__/*' \
  -not -path '*/node_modules/*' | grep -v '/\.[^/]*/' | grep -E '/\.venv/|^\./[^.]' | wc -l
# Log del LSP (busca 'too many files' / 'need to be indexed')
ls -t ~/.vscode-server/data/logs/*/exthost*/trinhanhngoc.vscode-odoo/"Odoo IDE.log" | head -1
```

### Configuraciones Estilo PyCharm

Configuraciones para mejorar productividad, similares a PyCharm:

#### Ruff - Linter y Formatter (Configurado para Odoo)

| Setting                            | Value                               | Purpose                                |
| ---------------------------------- | ----------------------------------- | -------------------------------------- |
| `editor.rulers`                    | `[88, 120]`                         | Guías visuales (Black: 88, Odoo: 120)  |
| `[python].editor.defaultFormatter` | `charliermarsh.ruff`                | Ruff formatter                         |
| `ruff.lineLength`                  | `120`                               | Línea máxima para Odoo                 |
| `ruff.lint.select`                 | `["E", "F", "W", "B", "C4", "SIM"]` | Reglas activas                         |
| `ruff.organizeImports`             | `false`                             | Deshabilitado (conflicto con Odoo IDE) |

#### Prettier - Markdown, XML, YAML, JSON (format-on-save)

| Setting                              | Value                    | Purpose                                                     |
| ------------------------------------ | ------------------------ | ----------------------------------------------------------- |
| `[markdown].editor.formatOnSave`     | `true`                   | Auto-formato al guardar (igual `[xml]`, `[yaml]`, `[json]`) |
| `[markdown].editor.defaultFormatter` | `esbenp.prettier-vscode` | Prettier 3.x (ver `package.json`)                           |
| `prettier.prettierPath`              | `node_modules/prettier`  | Módulo Prettier del workspace (requiere `npm ci` en raíz)   |
| `prettier.configPath`                | `prettier.config.cjs`    | Relativo al workspace; ver sección _Linting & Pre-commit_   |
| `editor.formatOnSaveMode`            | `file`                   | Formatear archivo completo (no solo líneas modificadas)     |

Ver **Linting & Pre-commit → Format-on-save** para setup (`npm ci`), troubleshooting y diferencia hook vs CI.

**Reglas ignoradas para Odoo:**

| Regla       | Razón                                                |
| ----------- | ---------------------------------------------------- |
| `E501`      | Longitud de línea (manejada por lineLength)          |
| `E402`      | Import no al inicio (patrón Odoo)                    |
| `B904`      | `raise ... from err` (UserError no expone internals) |
| `I` (isort) | Conflicto con Odoo IDE y convenciones OCA            |
| `UP009`     | `# -*- coding: utf-8 -*-` requerido por OCA          |

#### Navegación y Contexto

| Setting                            | Value  | Purpose                                  |
| ---------------------------------- | ------ | ---------------------------------------- |
| `editor.stickyScroll.enabled`      | `true` | Mantener clase/función visible en header |
| `editor.stickyScroll.maxLineCount` | `5`    | Máximo de líneas sticky                  |
| `breadcrumbs.enabled`              | `true` | Ruta de navegación de código             |
| `editor.minimap.enabled`           | `true` | Vista previa del archivo                 |

#### Colorización y Guías

| Setting                                    | Value      | Purpose                      |
| ------------------------------------------ | ---------- | ---------------------------- |
| `editor.bracketPairColorization.enabled`   | `true`     | Colorear pares de paréntesis |
| `editor.guides.bracketPairs`               | `"active"` | Resaltar par activo          |
| `editor.guides.indentation`                | `true`     | Guías de indentación         |
| `editor.guides.highlightActiveIndentation` | `true`     | Resaltar indentación activa  |

#### Inlay Hints (Tipos y Parámetros)

| Setting                                          | Value               | Purpose                           |
| ------------------------------------------------ | ------------------- | --------------------------------- |
| `editor.inlayHints.enabled`                      | `"onUnlessPressed"` | Mostrar hints (Ctrl para ocultar) |
| `python.analysis.inlayHints.functionReturnTypes` | `true`              | Tipos de retorno de funciones     |
| `python.analysis.inlayHints.variableTypes`       | `true`              | Tipos de variables                |
| `python.analysis.inlayHints.callArgumentNames`   | `"all"`             | Nombres de argumentos en llamadas |
| `editor.parameterHints.enabled`                  | `true`              | Nombres de parámetros en llamadas |

#### Auto-guardado y Limpieza

| Setting                        | Value          | Purpose                         |
| ------------------------------ | -------------- | ------------------------------- |
| `files.autoSave`               | `"afterDelay"` | Guardar automáticamente         |
| `files.autoSaveDelay`          | `1000`         | Delay de 1 segundo              |
| `files.trimTrailingWhitespace` | `true`         | Eliminar espacios al final      |
| `files.insertFinalNewline`     | `true`         | Nueva línea al final            |
| `files.trimFinalNewlines`      | `true`         | Eliminar líneas vacías al final |

#### Cursor y Scrolling

| Setting                             | Value        | Purpose                    |
| ----------------------------------- | ------------ | -------------------------- |
| `editor.smoothScrolling`            | `true`       | Scroll suave               |
| `editor.cursorBlinking`             | `"smooth"`   | Parpadeo suave del cursor  |
| `editor.cursorSmoothCaretAnimation` | `"on"`       | Animación del cursor       |
| `editor.renderLineHighlight`        | `"all"`      | Resaltar línea actual      |
| `editor.renderWhitespace`           | `"boundary"` | Mostrar espacios en bordes |

### Auto-Reindex de Odoo IDE

Para ejecutar reindex automáticamente al abrir el workspace:

1. Instalar extensión: `gabrielgrinberg.auto-run-command`
2. Configuración en `settings.json`:

```json
"auto-run-command.rules": [
    {
        "command": "odoo-ide.reindex",
        "message": "Reindexing Odoo addons..."
    }
]
```

### Extensiones Avanzadas PyCharm Professional

Extensiones que replican funcionalidades de PyCharm Professional:

#### Error Lens - Errores Inline

Muestra errores y warnings directamente en la línea de código:

| Setting                             | Value                          | Purpose                     |
| ----------------------------------- | ------------------------------ | --------------------------- |
| `errorLens.enabledDiagnosticLevels` | `["error", "warning", "info"]` | Niveles de diagnóstico      |
| `errorLens.delay`                   | `500`                          | Delay antes de mostrar (ms) |
| `errorLens.fontStyleItalic`         | `true`                         | Texto en cursiva            |

#### Mypy - Type Checker (Deshabilitado para Odoo)

Mypy está deshabilitado por defecto porque Odoo no tiene type stubs:

| Setting                     | Value   | Purpose                             |
| --------------------------- | ------- | ----------------------------------- |
| `mypy-type-checker.enabled` | `false` | Deshabilitado (Odoo sin type stubs) |

> **Nota:** Odoo IDE usa Pyright internamente. Para proyectos no-Odoo, habilitar Mypy.

#### Better Comments - Comentarios Coloreados

Comentarios con colores según el tipo:

| Prefijo | Color        | Uso                   |
| ------- | ------------ | --------------------- |
| `!`     | Rojo         | Alertas importantes   |
| `?`     | Azul         | Preguntas o dudas     |
| `*`     | Verde        | Información destacada |
| `TODO`  | Naranja      | Tareas pendientes     |
| `FIXME` | Rojo         | Bugs a corregir       |
| `//`    | Gris tachado | Código comentado      |

#### Git Graph - Visualización de Branches

Visualización gráfica de ramas y commits (similar a GitKraken):

```
Ctrl+Shift+P → "Git Graph: View Git Graph"
```

#### Semantic Highlighting

Colores personalizados para elementos Python:

| Token                         | Color     | Elemento                    |
| ----------------------------- | --------- | --------------------------- |
| `magicFunction:python`        | `#DCDCAA` | `__init__`, `__str__`, etc. |
| `function.declaration:python` | `#DCDCAA` | Declaraciones de funciones  |
| `*.decorator:python`          | `#D19A66` | Decoradores `@api.model`    |
| `*.typeHint:python`           | `#4EC9B0` | Type hints                  |
| `class:python`                | `#4EC9B0` | Nombres de clases           |

### Extensiones Recomendadas

Lista completa en `.vscode/extensions.json`. Destacadas:

| Extensión                    | Propósito                           |
| ---------------------------- | ----------------------------------- |
| `trinhanhngoc.vscode-odoo`   | Odoo IDE — resolución de modelos    |
| `charliermarsh.ruff`         | Linter + Formatter ultra-rápido     |
| `esbenp.prettier-vscode`     | Format-on-save .md/.xml/.yaml/.json |
| `usernamehw.errorlens`       | Errores inline en el código         |
| `aaron-bond.better-comments` | Comentarios coloreados              |
| `mhutchie.git-graph`         | Visualización de branches           |
| `eamodio.gitlens`            | Git avanzado                        |
| `mtxr.sqltools` + driver-pg  | Database tools (como DataGrip)      |
| `odoo.owl-vision`            | Soporte OWL en el editor            |

### Environment Variables (`.env`)

Variables de entorno para desarrollo Odoo. Copiar de `.env.example` y configurar:

```bash
# Odoo Runtime Configuration
ODOO_RC=config/<client>/dev.conf
PYTHONPATH=odoo:enterprise

# Locale Settings (Peruvian Spanish)
LANG=es_PE.UTF-8
LC_ALL=es_PE.UTF-8
TZ=America/Lima
```

| Variable      | Descripción                   | Nota                                          |
| ------------- | ----------------------------- | --------------------------------------------- |
| `ODOO_RC`     | Archivo de configuración Odoo | **Cambiar `<client>` por nombre del cliente** |
| `PYTHONPATH`  | Rutas para imports Python     | Odoo + Enterprise                             |
| `LANG/LC_ALL` | Locale del sistema            | Español Perú                                  |
| `TZ`          | Zona horaria                  | America/Lima                                  |

> **Importante:** Modificar `ODOO_RC` según el cliente activo: `config/cliente1/dev.conf`, `config/cliente2/dev.conf`,
> etc.

## Key Dependencies (requirements.txt)

Beyond Odoo's requirements, this environment includes:

| Category                        | Libraries                                                                                                        |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| XML/SOAP (Electronic Invoicing) | `signxml`, `xmlsig`, `suds-py3`, `PySimpleSOAP`                                                                  |
| PDF Processing                  | `pdfminer.six`, `img2pdf`, `fpdf`, `pdf417gen`                                                                   |
| Graphics Rendering              | `rlPyCairo` (backend PNG de reportlab — barcodes de `stock_barcode`; requiere `libcairo2-dev` en `setup_env.sh`) |
| Data Processing                 | `pandas`, `numpy`, `Pyarrow`                                                                                     |
| Cryptography                    | `PyJWT`, `pycryptodome`                                                                                          |
| Migration                       | `openupgradelib`                                                                                                 |
| Development                     | `ipython`, `pytest`, `pydevd-odoo`, `watchdog`, `nox`, `python-dotenv`                                           |
| Utilities                       | `docxtpl`, `polib`, `phonenumbers`, `pytesseract`, `jsonschema`, `html5lib`                                      |

## Security Vulnerabilities and Mitigations

> **Última revisión:** Junio 2026

### Resumen de Vulnerabilidades por Python

| Python    | Estado                | Vulnerabilidades Abiertas  |
| --------- | --------------------- | -------------------------- |
| 3.13+     | ✅ **Recomendado**    | 1 (sin parche disponible)  |
| 3.12      | ✅ Seguro             | 1 (sin parche disponible)  |
| 3.10-3.11 | ⚠️ **No recomendado** | 7+ (restricciones de Odoo) |

### CVEs Conocidos y Estado

| CVE            | Paquete      | Severidad | Parche   | Python ≥3.12  | Python <3.12     |
| -------------- | ------------ | --------- | -------- | ------------- | ---------------- |
| CVE-2025-66471 | urllib3      | **High**  | 2.6.0    | ✅ Corregido  | ❌ Sin fix (1.x) |
| CVE-2025-66418 | urllib3      | **High**  | 2.6.0    | ✅ Corregido  | ❌ Sin fix (1.x) |
| CVE-2025-50181 | urllib3      | Medium    | 2.5.0    | ✅ Corregido  | ❌ Sin fix (1.x) |
| CVE-2024-12797 | cryptography | Low       | 44.0.1   | ✅ Corregido  | ❌ Sin fix (3.x) |
| CVE-2025-64512 | pdfminer.six | **High**  | 20251107 | ✅ Corregido  | ❌ Sin fix       |
| CVE-2025-48994 | signxml      | Medium    | 4.0.4    | ✅ Corregido  | ❌ Sin fix (3.x) |
| CVE-2025-48995 | signxml      | Medium    | 4.0.4    | ✅ Corregido  | ❌ Sin fix (3.x) |
| GHSA-f83h      | pdfminer.six | **High**  | ❌ None  | ⚠️ Sin parche | ⚠️ Sin parche    |

### Vulnerabilidad sin Parche: pdfminer.six Pickle Deserialization

**GHSA-f83h-ghpp-7wcc** - Insecure Deserialization via pickle (CVSS 7.8 High)

**Descripción:** pdfminer.six usa `pickle` para cargar archivos CMap. Un atacante con acceso de escritura a directorios
en `CMAP_PATH` puede ejecutar código arbitrario.

**Requisitos para explotar:**

1. Atacante puede escribir en un directorio incluido en `CMAP_PATH`
2. Un proceso privilegiado (root/service) carga CMaps desde ese directorio

**Riesgo en Odoo:** 🟡 **Bajo-Medio**

- Requiere acceso local al servidor
- No explotable remotamente via PDFs procesados por Odoo
- `CMAP_PATH` debe estar mal configurado

**Mitigaciones:**

```bash
# No configurar CMAP_PATH a directorios escribibles por usuarios
# Verificar permisos de /tmp y directorios de upload
chmod 1777 /tmp  # sticky bit
```

### Python <3.12: Restricciones de Odoo

Las siguientes restricciones de Odoo impiden actualizar paquetes vulnerables en Python <3.12:

| Paquete      | Versión Odoo | Limitación                      |
| ------------ | ------------ | ------------------------------- |
| cryptography | 3.4.8        | pyopenssl requiere esta versión |
| lxml         | 4.x          | Odoo no compatible con lxml 5.x |
| urllib3      | 1.x          | requests de Odoo requiere 1.x   |

**Consecuencia:** Vulnerabilidades en urllib3, signxml, pdfminer.six no pueden parchearse.

### Mitigaciones Recomendadas

| Acción                                     | Impacto                | Prioridad |
| ------------------------------------------ | ---------------------- | --------- |
| **Usar Python ≥3.12**                      | Corrige 7 de 8 CVEs    | 🔴 Alta   |
| Ejecutar Odoo como usuario sin privilegios | Limita escalación      | 🔴 Alta   |
| No configurar `CMAP_PATH` escribible       | Mitiga pickle vuln     | 🟡 Media  |
| Firewall: limitar acceso a puertos Odoo    | Reduce superficie      | 🟡 Media  |
| Monitorear pdfminer.six para parche        | Preparar actualización | 🟢 Baja   |

### Dependabot y Marcadores de Versión Python

Dependabot no interpreta los marcadores `python_version` en requirements.txt, por lo que muestra alertas aunque las
vulnerabilidades estén corregidas para Python ≥3.12.

**Para verificar estado real:**

```bash
# Verificar versión Python activa
python --version

# Verificar versiones instaladas
pip show urllib3 cryptography pdfminer.six signxml

# Si Python ≥3.12, las versiones deberían ser:
# urllib3>=2.6.0, cryptography>=44.0.1, pdfminer.six>=20251230, signxml>=4.0.4
```

### Referencias

- [GHSA-f83h-ghpp-7wcc](https://github.com/pdfminer/pdfminer.six/security/advisories/GHSA-f83h-ghpp-7wcc) - pdfminer.six
  pickle
- [Dependabot Alerts](https://github.com/focuz-ai/odoo-env/security/dependabot) - Estado actual

## Peruvian Localization Modules

The environment is set up for Peruvian electronic invoicing and compliance:

- `l10n_pe_base`: EDI, partner extensions, POS, detractions
- `l10n_pe_accounting`: PLE books, SIRE with SUNAT API integration
- `l10n_pe_hr_payroll`: Payroll with PLAME, AFP, Renta 5ta

## Common Issues

**InterfaceError: connection already closed**

Occurs when editing Python code while Odoo runs with `--dev=all`:

```
psycopg2.InterfaceError: connection already closed
  File "odoo/service/server.py", line 507, in _run_cron
    pg_conn.poll()
```

**Cause:** When `max_cron_threads > 0` and using auto-reload, cron connections get closed abruptly.

**Solution:** Disable cron in development config:

```ini
# config/<client>/dev.conf
max_cron_threads = 0
```

> **Note:** Use `max_cron_threads = 1` only when testing cron jobs, without `--dev=all`.

**OSError: [Errno 24] inotify instance limit reached**

```bash
sudo sh -c 'echo "fs.inotify.max_user_instances = 1100000" >> /etc/sysctl.conf'
sudo sysctl -p
```

**Double parenthesis in prompt "((.venv))"** Fix the activate script:

```bash
# Edit .venv/bin/activate, find and replace:
# PS1="("'(.venv) '") ${PS1:-}"
# With:
# PS1="(.venv) ${PS1:-}"
```

**Dependency conflicts after pip install** Always install in order: `odoo/requirements.txt` first, then
`requirements.txt`.

```bash
pip install -r odoo/requirements.txt
pip install -r requirements.txt
pip check  # Verify no conflicts
```
