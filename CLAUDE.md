# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Odoo 18 development environment (o18-env) configured for multi-client/multi-project development with VSCode integration. It supports Odoo Community, Enterprise, and custom modules with a focus on Peruvian localization (l10n_pe).

## Repository Structure

```
o18-env/
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
git clone -b 18.0 git@github.com:focuz-ai/odoo-env.git o18-env
cd o18-env
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
4. Creates missing branches from upstream if needed (e.g., 18.0)
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
| `python.languageServer` | `"None"` | Permite que Odoo IDE maneje la resolución |
| `odoo.selectedProfile` | `""` | Deshabilita extensión oficial (evita conflictos) |
| `python.analysis.typeCheckingMode` | `"standard"` | Type checking |
| `editor.quickSuggestions.strings` | `"on"` | Autocompletado en strings (XML IDs) |
| `files.watcherInclude` | `["**"]` | Detectar cambios en symbolic links |

**Extensión requerida:** [Odoo IDE](https://marketplace.visualstudio.com/items?itemName=trinhanhngoc.vscode-odoo)
- Resolución de `_inherit` y navegación de modelos
- Autocompletado de campos y métodos
- Usa `odools.toml` para configuración de paths

**Configuración de Odoo IDE (`odools.toml`):**
```toml
[[config]]
name = "Odoo 18.0"
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

#### Límites de Línea y Formato

| Setting | Value | Purpose |
|---------|-------|---------|
| `editor.rulers` | `[88, 120]` | Guías visuales (Black: 88, Odoo: 120) |
| `[python].editor.formatOnSave` | `true` | Auto-formato al guardar |
| `[python].editor.defaultFormatter` | `ms-python.autopep8` | Formateador autopep8 |
| `[python].editor.codeActionsOnSave` | `organizeImports: explicit` | Organizar imports |

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

### Claude Code Environment Variables

Variables de entorno disponibles para comandos ejecutados por Claude Code:

```json
"claudeCode.environmentVariables": [
    "ODOO_RC=${workspaceFolder}/config/<client>/dev.conf",
    "PYTHONPATH=${workspaceFolder}/odoo:${workspaceFolder}/odoo-enterprise",
    "LANG=es_PE.UTF-8",
    "LC_ALL=es_PE.UTF-8",
    "TZ=America/Lima"
]
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
