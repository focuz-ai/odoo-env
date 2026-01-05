# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Odoo Master development environment (omaster-env) configured for multi-client/multi-project development with VSCode integration. It supports Odoo Community, Enterprise, and custom modules with a focus on Peruvian localization (l10n_pe).

## Repository Structure

```
omaster-env/
├── odoo/              # Odoo Community (cloned)
├── odoo-enterprise/   # Odoo Enterprise (cloned)
├── odoo-themes/       # Odoo Themes (cloned)
├── config/            # Per-client config files (dev.conf, main.conf)
│   └── <client>/      # Client-specific configurations
├── src/
│   ├── dev/           # Development addons (focuz-ai, yellow-brain-labs)
│   ├── projects/      # Client-specific addons organized by branch
│   │   └── <client>/{dev,main,temp}/
│   └── migrate/       # Migration work
├── vendor/            # Third-party addons
└── .venv/             # Python 3.13 virtual environment
```

## Python Environment

**Python 3.13** (current, stable)

```bash
# Activate virtual environment
source .venv/bin/activate
```

### Python Version Compatibility

| Python | Status | Notes |
|--------|--------|-------|
| 3.10 | ✅ Supported | Minimum version |
| 3.11 | ✅ Supported | Legacy stable |
| 3.12 | ✅ Supported | Previous stable |
| 3.13 | ✅ Current | Recommended, latest features |

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

```bash
# 1. Activate environment
source .venv/bin/activate

# 2. Install Odoo dependencies first (locks cryptography, Pillow, lxml, etc.)
pip install -r odoo/requirements.txt

# 3. Install project dependencies (respects Odoo versions)
pip install -r requirements.txt

# 4. Verify no conflicts
pip check
```

### Key Library Versions by Python

| Library | Python 3.10-3.11 | Python 3.12 | Python 3.13+ |
|---------|------------------|-------------|--------------|
| cryptography | 3.4.8 | 42.0.8 | 42.0.8 |
| Pillow | 9.0.1 / 9.4.0 | 10.2.0 | 11.1.0 |
| pdfminer.six | 20211012 | 20231228 | 20231228 |
| signxml | 3.1.1 | 3.2.2+ | 3.2.2+ |
| pandas | 1.3.5 | 2.2.3+ | 2.2.3+ |
| numpy | 1.26.x | 1.26.x | 2.4.x+ |
| PyArrow | 15.x | 15.x | 18.x+ |

## Configuration Files

- **`.env`**: Environment variables (ODOO_TAG, GITHUB_USER, GITHUB_ACCESS_TOKEN)
- **`odools.toml`**: Defines addons paths for the project
- **`config/<client>/<branch>.conf`**: Odoo configuration per client/branch
- **`clone-addons.txt`**: Controls which repositories to clone via `clone-addons.sh`

## Initial Setup

```bash
# Clone and configure
git clone -b master git@github.com:focuz-ai/odoo-env.git omaster-env
cd omaster-env
cp .env.example .env
cp odools.toml.example odools.toml
cp config/dev.conf.example config/<client>/dev.conf
# Para producción:
# cp config/prod.conf.example config/<client>/prod.conf
cp .vscode/launch.json.example .vscode/launch.json

# Clone Odoo repositories
./clone-addons.sh

# Create Python 3.13 virtual environment
python3.13 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install --upgrade pip setuptools wheel
pip install -r odoo/requirements.txt
pip install -r requirements.txt
```

## Setup Environment Script

The `setup_env.sh` script prepares the development environment automatically.

### Usage

```bash
./setup_env.sh                  # Install with Python 3.13 (default)
./setup_env.sh -p 3.12          # Install with Python 3.12
./setup_env.sh --help           # Show help
```

### What it installs

| Component | Description |
|-----------|-------------|
| Python | Specified version (3.10-3.14) + pip + venv |
| Odoo dependencies | Build tools, libraries (libsasl2, libldap2, etc.) |
| PostgreSQL client | psql command-line tool |
| wkhtmltopdf | PDF generation for Odoo reports |

### wkhtmltopdf Version Selection

The script automatically selects the correct wkhtmltopdf version based on `ODOO_TAG` in `.env`:

| ODOO_TAG | wkhtmltox Version |
|----------|-------------------|
| 14.0 - 19.0, master | 0.12.6.1-3 |
| 12.0 - 13.0 | 0.12.5-1 |

The script handles fallback for distributions without official packages (e.g., noble → jammy).

### Security Warning for Python <3.12

When selecting Python versions below 3.12, the script displays a security warning and requires confirmation:

| CVE | Package | Severity | Reason |
|-----|---------|----------|--------|
| CVE-2025-66471, CVE-2025-66418 | urllib3 | High | Requires urllib3 1.x |
| CVE-2024-12797 | cryptography | Low | Requires cryptography 3.x |
| CVE-2025-48994, CVE-2025-48995 | signxml | Medium | Requires lxml 4.x |
| CVE-2025-64512 | pdfminer.six | High | Requires cryptography 3.x |

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

| Option | Description |
|--------|-------------|
| `-s, --sync` | Sync focuz-ai forks with upstream Odoo (fetch, merge, push) |
| `-h, --help` | Show help message |

### Repositories Managed

| Local Folder | Fork (focuz-ai) | Upstream (Odoo) |
|--------------|-----------------|-----------------|
| `odoo/` | focuz-ai/odoo | odoo/odoo |
| `odoo-enterprise/` | focuz-ai/odoo-enterprise | odoo/enterprise |
| `odoo-themes/` | focuz-ai/odoo-design-themes | odoo/design-themes |

### Sync Functionality (--sync)

When executed with `--sync`, the script:
1. Clones repositories from focuz-ai forks
2. Adds upstream Odoo remotes automatically
3. Fetches latest changes from upstream
4. Creates missing branches from upstream if needed (e.g., master)
5. Merges upstream changes into the fork
6. Pushes updates back to focuz-ai repositories

### Requirements

Configure `.env` with GitHub credentials for private repos and sync:
```bash
GITHUB_USER=your_username
GITHUB_ACCESS_TOKEN=ghp_your_token
```

### Configuration (clone-addons.txt)

```bash
# Format: <type> <repo_url> <condition>
public https://github.com/focuz-ai/odoo true
themes https://github.com/focuz-ai/odoo-design-themes true
enterprise https://github.com/focuz-ai/odoo-enterprise true
```

## Database Configuration

Default PostgreSQL settings:
- Host: 127.0.0.1
- Port: 5454 (non-standard to avoid conflicts)
- User: odoo
- Password: odoo

## Odoo 18 Coding Guidelines

- Use `@api.model_create_multi` instead of `@api.model` for create methods
- All models require `_description` attribute
- Boolean field attributes must be actual booleans (`readonly=True` not `readonly="True"`)
- No `_()` translation wrapper in class-level Selection field definitions
- Related fields don't need `selection` redefinition
- FontAwesome `<i>` tags require `title` attribute for accessibility

## Git Submodule Management

This project uses git submodules for organization-specific module repositories.

```bash
# Update all submodules
git submodule update --remote --merge

# Update specific submodule
git submodule update --remote --merge <submodule_path>

# After pull with submodule changes
git pull --recurse-submodules

# Initialize submodules after clone
git submodule update --init --recursive
```

## VSCode Integration

Launch configurations in `.vscode/launch.json`:

| Configuration | Description | Key Args |
|---------------|-------------|----------|
| `Odoo: Development` | Run server with hot reload | `--dev=all` |
| `Odoo: Install Module` | Install module and exit | `-i <module> --stop-after-init` |
| `Odoo: Update Module` | Update module and exit | `-u <module> --stop-after-init` |
| `Odoo: Run Tests` | Run module tests | `--test-enable --log-level=test` |
| `Odoo: Shell (IPython)` | Interactive shell | `--shell-interface ipython` |
| `Odoo: Scaffold Module` | Create new module structure | `scaffold <name> src/dev/` |

All configurations use debugpy with `frozen_modules=off` for debugging support.

### Launch Setup
```bash
cp .vscode/launch.json.example .vscode/launch.json
# Edit launch.json: replace <database> and <module_name> placeholders
```

### Workspace Settings (`.vscode/settings.json`)

| Setting | Value | Purpose |
|---------|-------|---------|
| `python.languageServer` | `"None"` | Pylance deshabilitado (Odoo IDE usa Pyright) |
| `odoo.selectedProfile` | `""` | Deshabilita extensión oficial Odoo |
| `python.analysis.typeCheckingMode` | `"basic"` | Recomendado por Odoo IDE |
| `python.analysis.diagnosticMode` | `"openFilesOnly"` | Solo archivos abiertos |
| `python.analysis.extraPaths` | `[odoo, odoo/addons, ...]` | Paths para resolver imports |
| `editor.quickSuggestions.strings` | `"on"` | Autocompletado en strings (XML IDs) |
| `files.watcherInclude` | `["**"]` | Detectar cambios en symbolic links |

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
- **`settings.json` (`python.analysis.*`):** Configuración para Pylance
- **`pyrightconfig.json`:** Configuración para Odoo IDE (su Pyright interno)

Ambos archivos tienen configuraciones similares para consistencia:

```json
{
    "typeCheckingMode": "basic",
    "reportMissingTypeStubs": false,
    "reportMissingModuleSource": false,
    "reportUnknownMemberType": false,
    "reportUnknownArgumentType": false,
    "extraPaths": ["odoo", "odoo/addons", "odoo-enterprise"]
}
```

| Diagnóstico | Razón para ignorar |
|-------------|-------------------|
| `reportMissingTypeStubs` | dateutil, lxml, etc. sin stubs |
| `reportMissingModuleSource` | Módulos Odoo dinámicos |
| `reportUnknownMemberType` | Campos `self.field_name` dinámicos |
| `reportUnknownArgumentType` | Argumentos dinámicos en métodos Odoo |

**Extensión requerida:** [Odoo IDE](https://marketplace.visualstudio.com/items?itemName=trinhanhngoc.vscode-odoo)
- Resolución de `_inherit` y navegación de modelos
- Autocompletado de campos y métodos
- Usa `odools.toml` para configuración de paths

**Configuración de Odoo IDE (`odools.toml`):**
```toml
[[config]]
name = "Odoo Master"
odoo_path = "${workspaceFolder}/odoo"
addons_paths = [
    "${workspaceFolder}/odoo/addons",
    "${workspaceFolder}/odoo-enterprise",
    "${workspaceFolder}/odoo-themes",
]
```

**Comandos útiles de Odoo IDE:**
- `Ctrl+Shift+P` → "Odoo: Reindex Addons" - Reindexar después de cambios
- `Ctrl+Shift+P` → "Odoo: Restart Language Server" - Reiniciar si hay problemas

> **Nota:** La extensión oficial `odoo.odoo` puede causar conflictos. Deshabilitar para el workspace si hay problemas.

### Configuraciones Estilo PyCharm

Configuraciones para mejorar productividad, similares a PyCharm:

#### Ruff - Linter y Formatter (Configurado para Odoo)

| Setting | Value | Purpose |
|---------|-------|---------|
| `editor.rulers` | `[88, 120]` | Guías visuales (Black: 88, Odoo: 120) |
| `[python].editor.defaultFormatter` | `charliermarsh.ruff` | Ruff formatter |
| `ruff.lineLength` | `120` | Línea máxima para Odoo |
| `ruff.lint.select` | `["E", "F", "W", "B", "C4", "SIM"]` | Reglas activas |
| `ruff.organizeImports` | `false` | Deshabilitado (conflicto con Odoo IDE) |

**Reglas ignoradas para Odoo:**

| Regla | Razón |
|-------|-------|
| `E501` | Longitud de línea (manejada por lineLength) |
| `E402` | Import no al inicio (patrón Odoo) |
| `B904` | `raise ... from err` (UserError no expone internals) |
| `I` (isort) | Conflicto con Odoo IDE y convenciones OCA |
| `UP009` | `# -*- coding: utf-8 -*-` requerido por OCA |

#### Navegación y Contexto

| Setting | Value | Purpose |
|---------|-------|---------|
| `editor.stickyScroll.enabled` | `true` | Mantener clase/función visible en header |
| `editor.stickyScroll.maxLineCount` | `5` | Máximo de líneas sticky |
| `breadcrumbs.enabled` | `true` | Ruta de navegación de código |
| `editor.minimap.enabled` | `true` | Vista previa del archivo |

#### Colorización y Guías

| Setting | Value | Purpose |
|---------|-------|---------|
| `editor.bracketPairColorization.enabled` | `true` | Colorear pares de paréntesis |
| `editor.guides.bracketPairs` | `"active"` | Resaltar par activo |
| `editor.guides.indentation` | `true` | Guías de indentación |
| `editor.guides.highlightActiveIndentation` | `true` | Resaltar indentación activa |

#### Inlay Hints (Tipos y Parámetros)

| Setting | Value | Purpose |
|---------|-------|---------|
| `editor.inlayHints.enabled` | `"onUnlessPressed"` | Mostrar hints (Ctrl para ocultar) |
| `python.analysis.inlayHints.functionReturnTypes` | `true` | Tipos de retorno de funciones |
| `python.analysis.inlayHints.variableTypes` | `true` | Tipos de variables |
| `python.analysis.inlayHints.callArgumentNames` | `"all"` | Nombres de argumentos en llamadas |
| `editor.parameterHints.enabled` | `true` | Nombres de parámetros en llamadas |

#### Auto-guardado y Limpieza

| Setting | Value | Purpose |
|---------|-------|---------|
| `files.autoSave` | `"afterDelay"` | Guardar automáticamente |
| `files.autoSaveDelay` | `1000` | Delay de 1 segundo |
| `files.trimTrailingWhitespace` | `true` | Eliminar espacios al final |
| `files.insertFinalNewline` | `true` | Nueva línea al final |
| `files.trimFinalNewlines` | `true` | Eliminar líneas vacías al final |

#### Cursor y Scrolling

| Setting | Value | Purpose |
|---------|-------|---------|
| `editor.smoothScrolling` | `true` | Scroll suave |
| `editor.cursorBlinking` | `"smooth"` | Parpadeo suave del cursor |
| `editor.cursorSmoothCaretAnimation` | `"on"` | Animación del cursor |
| `editor.renderLineHighlight` | `"all"` | Resaltar línea actual |
| `editor.renderWhitespace` | `"boundary"` | Mostrar espacios en bordes |

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

| Setting | Value | Purpose |
|---------|-------|---------|
| `errorLens.enabledDiagnosticLevels` | `["error", "warning", "info"]` | Niveles de diagnóstico |
| `errorLens.delay` | `500` | Delay antes de mostrar (ms) |
| `errorLens.fontStyleItalic` | `true` | Texto en cursiva |

#### Mypy - Type Checker (Deshabilitado para Odoo)

Mypy está deshabilitado por defecto porque Odoo no tiene type stubs:

| Setting | Value | Purpose |
|---------|-------|---------|
| `mypy-type-checker.enabled` | `false` | Deshabilitado (Odoo sin type stubs) |

> **Nota:** Odoo IDE usa Pyright internamente. Para proyectos no-Odoo, habilitar Mypy.

#### Better Comments - Comentarios Coloreados

Comentarios con colores según el tipo:

| Prefijo | Color | Uso |
|---------|-------|-----|
| `!` | Rojo | Alertas importantes |
| `?` | Azul | Preguntas o dudas |
| `*` | Verde | Información destacada |
| `TODO` | Naranja | Tareas pendientes |
| `FIXME` | Rojo | Bugs a corregir |
| `//` | Gris tachado | Código comentado |

#### Git Graph - Visualización de Branches

Visualización gráfica de ramas y commits (similar a GitKraken):

```
Ctrl+Shift+P → "Git Graph: View Git Graph"
```

#### Semantic Highlighting

Colores personalizados para elementos Python:

| Token | Color | Elemento |
|-------|-------|----------|
| `magicFunction:python` | `#DCDCAA` | `__init__`, `__str__`, etc. |
| `function.declaration:python` | `#DCDCAA` | Declaraciones de funciones |
| `*.decorator:python` | `#D19A66` | Decoradores `@api.model` |
| `*.typeHint:python` | `#4EC9B0` | Type hints |
| `class:python` | `#4EC9B0` | Nombres de clases |

### Extensiones Recomendadas

| Extensión | Propósito |
|-----------|-----------|
| `charliermarsh.ruff` | Linter + Formatter ultra-rápido |
| `usernamehw.errorlens` | Errores inline en el código |
| `ms-python.mypy-type-checker` | Type checking estricto |
| `aaron-bond.better-comments` | Comentarios coloreados |
| `mhutchie.git-graph` | Visualización de branches |
| `eamodio.gitlens` | Git avanzado |
| `mtxr.sqltools` | Database tools (como DataGrip) |

### Environment Variables (`.env`)

Variables de entorno para desarrollo Odoo. Copiar de `.env.example` y configurar:

```bash
# Odoo Runtime Configuration
ODOO_RC=config/<client>/dev.conf
PYTHONPATH=odoo:odoo-enterprise

# Locale Settings (Peruvian Spanish)
LANG=es_PE.UTF-8
LC_ALL=es_PE.UTF-8
TZ=America/Lima
```

| Variable | Descripción | Nota |
|----------|-------------|------|
| `ODOO_RC` | Archivo de configuración Odoo | **Cambiar `<client>` por nombre del cliente** |
| `PYTHONPATH` | Rutas para imports Python | Odoo + Enterprise |
| `LANG/LC_ALL` | Locale del sistema | Español Perú |
| `TZ` | Zona horaria | America/Lima |

> **Importante:** Modificar `ODOO_RC` según el cliente activo: `config/cliente1/dev.conf`, `config/cliente2/dev.conf`, etc.

## Key Dependencies (requirements.txt)

Beyond Odoo's requirements, this environment includes:

| Category | Libraries |
|----------|-----------|
| XML/SOAP (Electronic Invoicing) | `signxml`, `xmlsig`, `suds-py3`, `PySimpleSOAP` |
| PDF Processing | `pdfminer.six`, `img2pdf`, `fpdf`, `pdf417gen` |
| Data Processing | `pandas`, `numpy`, `Pyarrow` |
| Cryptography | `PyJWT`, `pycryptodome` |
| Development | `ipython`, `pytest`, `pydevd-odoo`, `watchdog` |

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

**Double parenthesis in prompt "((.venv))"**
Fix the activate script:
```bash
# Edit .venv/bin/activate, find and replace:
# PS1="("'(.venv) '") ${PS1:-}"
# With:
# PS1="(.venv) ${PS1:-}"
```

**Dependency conflicts after pip install**
Always install in order: `odoo/requirements.txt` first, then `requirements.txt`.
```bash
pip install -r odoo/requirements.txt
pip install -r requirements.txt
pip check  # Verify no conflicts
```
