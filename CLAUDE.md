# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Odoo 16.0 development environment (o16-env) configured for multi-client/multi-project development with VSCode integration. It supports Odoo Community, Enterprise, and custom modules with a focus on Peruvian localization (l10n_pe).

## Repository Structure

```
o16-env/
├── odoo/              # Odoo Community (cloned, per clone-addons.txt)
├── enterprise/        # Odoo Enterprise (cloned)
├── design-themes/     # Odoo Design Themes (cloned)
├── config/            # Per-client config files (dev.conf, main.conf, ...)
│   └── <client>/      # Client-specific configurations (e.g. agrovet, jriffo, pancita)
├── src/
│   ├── dev/           # Development addons (focuz-ai, yellow-brain-labs)
│   ├── projects/      # Client-specific addons organized by branch
│   │   └── <client>/{dev,main,temp}/
│   └── migrate/       # Version-migration work-in-progress (e.g. 17.0/, 18.0/)
├── vendor/            # Third-party addons (source dirs + packaged .zip releases)
└── .venv/             # Python virtual environment (3.10-3.13, see below)
```

> Los nombres de carpetas clonadas son `enterprise/` y `design-themes/` (no
> `odoo-enterprise/`/`odoo-themes/` — nombres antiguos ya retirados de todo el repo,
> incluyendo templates `.example`). Son configurables vía `ENTERPRISE_ADDONS`/`THEMES_ADDONS`
> en `.env` (ver sección "Environment Variables" bajo VSCode Integration).

## Python Environment

**Python 3.11 is the recommended interpreter for this repo (Odoo 16.0)** — 3.10 also works
(with the gevent/Cython workaround, see Common Issues). **Do NOT use Python 3.12+ for Odoo 16.**

> ⚠️ **Python 3.12+ breaks Peruvian EDI signing on Odoo 16.** On Python ≥3.12,
> `odoo/requirements.txt` pins `pyopenssl==24.1.0`, and pyOpenSSL 24 **removed the
> module-level `OpenSSL.crypto.sign` / `verify` functions** (deprecated since 3.0). The
> SUNAT electronic-invoicing / signing code (l10n_pe) calls them, so it crashes at runtime
> with `AttributeError: module 'OpenSSL.crypto' has no attribute 'sign'`. On Python 3.10/3.11
> Odoo pins `pyopenssl==20.0.1`, which still provides those functions. See Common Issues.

Python 3.12 only becomes the recommendation from **Odoo 18.0+** (where the framework and
localizations no longer depend on the removed pyOpenSSL APIs). Python 3.13 targets Odoo 17+.
Don't default to 3.12/3.13 here without checking which Odoo series is actually targeted
(`ODOO_TAG` in `.env`).

```bash
# Activate virtual environment
source .venv/bin/activate
```

### Python Version Compatibility

| Python | Status | Notes |
|--------|--------|-------|
| 3.10 | ⚠️ Works, needs workaround | `gevent` fails to build with modern setuptools/Cython (see Common Issues); also needs the dep pins below |
| 3.11 | ✅ **Recommended for Odoo 16** | Odoo pins `pyopenssl==20.0.1` (keeps `crypto.sign` → EDI works). Needs `setuptools<81`, `pandas` via `--no-build-isolation`, `cryptography==3.4.8`, `google-auth<2.24` (see Common Issues) |
| 3.12 | ❌ **Do NOT use on Odoo 16** | Odoo pins `pyopenssl==24.1.0`, which removed `OpenSSL.crypto.sign`/`verify` → l10n_pe EDI signing crashes. Only recommended from Odoo 18.0+ |
| 3.13 | ❌ **Do NOT use on Odoo 16** | Same pyOpenSSL 24 EDI breakage as 3.12; recommended only for Odoo 17+ |

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

# Run tests for a module (installs it first)
python odoo/odoo-bin -c config/<client>/dev.conf -d <database> --test-enable -i <module_name> --stop-after-init

# Run a single test (module already installed: use -u, not -i)
python odoo/odoo-bin -c config/<client>/dev.conf -d <database> -u <module_name> \
    --test-enable --test-tags :TestClassName.test_method_name --stop-after-init

# Run tests for one module without touching others (by module tag)
python odoo/odoo-bin -c config/<client>/dev.conf -d <database> -u <module_name> \
    --test-enable --test-tags /<module_name> --stop-after-init

# Odoo shell
python odoo/odoo-bin shell -d <database> -c config/<client>/dev.conf

# Odoo shell with IPython
python odoo/odoo-bin shell -d <database> -c config/<client>/dev.conf --xmlrpc-port 8888 --gevent-port 8899 --shell-interface ipython

# Scaffold new module
python odoo/odoo-bin scaffold <module_name> src/dev/<organization>/

# Development mode with auto-reload (covers Python/XML/QWeb; cheaper than --dev=all)
python odoo/odoo-bin -c config/<client>/dev.conf --dev=xml,reload,qweb

# Use --dev=all only when touching JS/OWL/SCSS (recompiles assets on every request)
python odoo/odoo-bin -c config/<client>/dev.conf --dev=all
```

## Linting, Formatting & Pre-commit

```bash
# Run all hooks against staged files (what the git hook runs on commit)
pre-commit run

# Run against specific files
pre-commit run --files path/to/file.py

# Run everything (NOT recommended on first pass over existing code — see below)
pre-commit run --all-files

# Ruff directly (lint + format), scoped to your module
ruff check src/dev/<organization>/<module>/
ruff format src/dev/<organization>/<module>/

# Prettier (JS/XML/YAML/MD) — requires --ignore-path .prettierignore, NOT the
# default .gitignore-based ignore (src/dev/*, src/projects/* are gitignored
# wholesale in this repo, which would silently skip all real module code)
npm run format
npm run format:file -- path/to/file.xml
```

> **First pass warning:** don't run `pre-commit run --all-files` or `npm run format`
> (bare) over existing code — auto-fix hooks would reformat the whole tree in one
> diff. Let hooks act on files you actually touch, module by module.
> Details, gotchas, and the pylint-odoo/ruff config rationale (license-allowed,
> quote-style, etc.) are in [docs/dev-environment-optimization.md](docs/dev-environment-optimization.md).

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

| Library | Python 3.10-3.11 | Python 3.12+ | Security Notes |
|---------|------------------|--------------|----------------|
| cryptography | 3.4.8 ⚠️ | ≥44.0.1 ✅ | CVE-2024-12797 fixed in 44.0.1 |
| urllib3 | 1.26.19 ⚠️ | ≥2.6.0 ✅ | CVE-2025-66471/66418 fixed in 2.6.0 |
| pdfminer.six | 20211012 ⚠️ | ≥20251230 ✅ | CVE-2025-64512 fixed; pickle vuln open |
| signxml | 3.1.1 ⚠️ | ≥4.0.4 ✅ | CVE-2025-48994/48995 fixed in 4.0.4 |
| Pillow | 9.0.1 / 9.4.0 | ≥10.3.0 / 11.1.0 | CVE-2024-28219 fixed |
| pandas | 1.3.5 | ≥2.2.3 | - |
| numpy | 1.26.x | 1.26.x / 2.4.x+ | - |
| PyArrow | 15.x | 15.x / 18.x+ | - |

> ⚠️ = Vulnerable (Odoo constraints prevent update) | ✅ = Patched

## Configuration Files

- **`.env`**: Environment variables (ODOO_TAG, GITHUB_USER, GITHUB_ACCESS_TOKEN)
- **`odools.toml`**: Defines addons paths for the project
- **`config/<client>/<branch>.conf`**: Odoo configuration per client/branch
- **`clone-addons.txt`**: Controls which repositories to clone via `clone-addons.sh`

## Initial Setup

```bash
# Clone and configure
git clone -b 16.0 git@github.com:focuz-ai/odoo-env.git o16-env
cd o16-env
cp .env.example .env
cp odools.toml.example odools.toml
cp config/dev.conf.example config/<client>/dev.conf
# Para producción:
# cp config/prod.conf.example config/<client>/prod.conf
cp .vscode/launch.json.example .vscode/launch.json

# Clone Odoo repositories
./clone-addons.sh

# Create Python 3.11 virtual environment (recommended for Odoo 16 — 3.12+ breaks EDI signing)
python3.11 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install --upgrade pip setuptools wheel
pip install -r odoo/requirements.txt
pip install -r requirements.txt
pip check

# Code quality tooling (pre-commit: ruff + pylint-odoo; prettier: JS/XML/YAML/MD)
pip install pre-commit
pre-commit install
npm install
```

> Detalle de cada herramienta en [docs/dev-environment-optimization.md](docs/dev-environment-optimization.md#8-pylint-odoo-oca-en-pre-commit).

## Setup Environment Script

The `setup_env.sh` script prepares the development environment automatically.

### Usage

```bash
./setup_env.sh                  # Install with Python 3.13 (script default)
./setup_env.sh -p 3.11          # Install with Python 3.11 (recommended for this Odoo 16 repo)
./setup_env.sh --help           # Show help
```

> El default del script (3.13) apunta a Odoo 17+ y **rompe el firmado EDI en Odoo 16**
> (pyOpenSSL 24 sin `crypto.sign`, ver Common Issues); para este repo (Odoo 16) pasa siempre
> `-p 3.11` explícitamente.

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
| 14.0 - 19.0 | 0.12.6.1-3 |
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

> ⚠️ **En Odoo 16 NO puedes subir a Python ≥3.12 para esquivar estos CVEs:** rompe el
> firmado EDI de SUNAT (pyOpenSSL 24 sin `crypto.sign`, ver Common Issues). Para Odoo 16
> la única opción soportada es **Python 3.11** (o 3.10) asumiendo estos CVEs y mitigándolos
> operativamente (usuario sin privilegios, firewall, no exponer puertos). El salto a
> Python 3.12 como fix de seguridad aplica desde **Odoo 18.0+**.

**Recommendation:** Use Python 3.11 for Odoo 16. Python 3.12+ is only appropriate from
Odoo 18.0+, where it fixes these CVEs without breaking EDI.

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
| `odoo/` | focuz-ai/odoo-fork | odoo/odoo |
| `enterprise/` | focuz-ai/odoo-fork-enterprise | odoo/enterprise |
| `design-themes/` | focuz-ai/odoo-fork-design-themes | odoo/design-themes |

> El mapeo fork↔upstream real para cada carpeta lo define `clone-addons.txt` — puede
> apuntar directo al upstream (p. ej. `odoo/odoo`, `odoo/design-themes`) en vez del fork
> cuando no hay cambios propios que sincronizar en esa carpeta (típicamente solo
> `enterprise/` necesita el fork). Verifica ese archivo antes de asumir de dónde se
> clona cada carpeta.

### Sync Functionality (--sync)

When executed with `--sync`, the script:
1. Clones repositories from focuz-ai forks
2. Adds upstream Odoo remotes automatically
3. Fetches latest changes from upstream
4. Creates missing branches from upstream if needed (e.g., 16.0)
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
public https://github.com/odoo/odoo true
themes https://github.com/odoo/design-themes true
enterprise https://github.com/focuz-ai/odoo-fork-enterprise true
```

## Database Configuration

Default PostgreSQL settings:
- Host: 127.0.0.1
- Port: 5454 (non-standard to avoid conflicts)
- User: odoo
- Password: odoo

## Odoo Coding & Git Guidelines

Los estándares de desarrollo (coding guidelines, ORM/rendimiento, seguridad, OWL/SCSS,
testing) y las git guidelines viven ahora en **[`docs/`](docs/README.md)** — única
fuente de verdad, estandarizada con la plantilla del sistema `odoo-openspec`:

| Tema | Documento |
|------|-----------|
| Rutas del entorno, runtime, `odools.toml`, `dev.conf`, `launch.json` | [docs/environment.md](docs/environment.md) |
| Convenciones, estructura de módulo, orden de atributos, naming, XML, SCSS, i18n, permisos | [docs/conventions.md](docs/conventions.md) |
| SOLID/Clean Code en clave Odoo, manejo de errores, logging, anti-patrones | [docs/engineering-principles.md](docs/engineering-principles.md) |
| ORM, N+1, computes, índices, SQL, transacciones/savepoints, excepciones | [docs/orm-performance.md](docs/orm-performance.md) |
| ACL/CSV, grupos, record rules, sudo, multi-compañía, controladores | [docs/security.md](docs/security.md) |
| OWL 2, QWeb-JS, assets/registry, widgets, SCSS, tests del web client | [docs/frontend-owl.md](docs/frontend-owl.md) |
| TransactionCase/HttpCase + framework JS de la versión, trazabilidad, upgrade-safety | [docs/testing.md](docs/testing.md) |
| EDI/autoridad fiscal: envío (`account.edi.format`), idempotencia, seguridad, auditoría | [docs/edi-integrations.md](docs/edi-integrations.md) |
| Migrar un módulo entre series Odoo (APIs, vistas, frontend, OpenUpgrade) | [docs/version-migration.md](docs/version-migration.md) |
| Formato de commit, tags, ramas, PR (estilo Odoo) | [docs/git-guidelines.md](docs/git-guidelines.md) |

> Los agentes IA del flujo resuelven `docs/<tema>.md` contra este `docs/` (estándar de
> la versión activa). El resto de este `CLAUDE.md` cubre el **entorno** (Python, deps,
> IDE, etc.), no el código del módulo.

## Contributing Upstream to Odoo

Este proyecto mantiene forks (`focuz-ai/odoo-fork*`) específicamente para poder contribuir
fixes/features de vuelta a `odoo/odoo` — no solo para consumir código. Workflow real:

```bash
cd odoo
git remote add upstream https://github.com/odoo/odoo.git   # si no existe aún
git fetch upstream 16.0
git checkout -b 16.0-fix-descripcion upstream/16.0

# ... cambios + commit con formato [TAG] module: ... (ver docs/git-guidelines.md) ...

git push origin 16.0-fix-descripcion
gh pr create --repo odoo/odoo --base 16.0 \
  --head focuz-ai:16.0-fix-descripcion \
  --title "[FIX] module: descripción corta"
```

**CLA obligatorio antes de contribuir:** crear `odoo/doc/cla/individual/<github_username>.md`
siguiendo el formato de archivos existentes y abrir PR con tag `[CLA]`.

**Sincronizar fork con upstream** (equivalente manual de `./clone-addons.sh --sync`):
```bash
cd odoo
git fetch upstream
git checkout 16.0
git merge upstream/16.0
git push origin 16.0
```

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
| `Odoo: Development` | Run server with hot reload | `--dev=xml,reload,qweb` |
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
| `python.analysis.extraPaths` | `[odoo, odoo/addons, enterprise, design-themes, vendor/OCA]` | Paths para resolver imports |
| `editor.quickSuggestions.strings` | `"on"` | Autocompletado en strings (XML IDs) |
| `files.watcherInclude` | `["**"]` | Detectar cambios en symbolic links |
| `files.watcherExclude` / `search.exclude` / `files.exclude` | `enterprise/`, `design-themes/`, `vendor/`, `.venv/`, `__pycache__/`, `.ruff_cache/` | Reducir CPU del file watcher y del `Ctrl+Shift+F` global (no afecta el scope del Odoo IDE, que vive en `pyrightconfig.json`) |
| `prettier.ignorePath` | `".prettierignore"` | Evita que Prettier herede el `.gitignore` (que ignora `src/dev/*`/`src/projects/*` en bloque) |

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
    "extraPaths": ["odoo", "odoo/addons", "enterprise", "design-themes"]
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
    "${workspaceFolder}/enterprise",
    "${workspaceFolder}/design-themes",
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
| `ms-python.debugpy` | Depuración de Python (requerido por `launch.json`: `"type": "debugpy"`) |
| `esbenp.prettier-vscode` | Format-on-save para JS/XML/YAML/MD (ver `.prettierignore`) |
| `usernamehw.errorlens` | Errores inline en el código |
| `ms-python.mypy-type-checker` | Type checking estricto |
| `aaron-bond.better-comments` | Comentarios coloreados |
| `mhutchie.git-graph` | Visualización de branches |
| `eamodio.gitlens` | Git avanzado |
| `mtxr.sqltools` | Database tools (como DataGrip) |
| `DotJoshJohnson.xml`, `formulahendry.auto-complete-tag` | Soporte y autocompletado XML (vistas, QWeb) |
| `mrorz.language-gettext` | Soporte para archivos `.po` (traducciones) |

### Environment Variables (`.env`)

Variables de entorno para desarrollo Odoo. Copiar de `.env.example` y configurar:

```bash
# Repository Paths (nombres de carpeta configurables)
ENTERPRISE_ADDONS=enterprise
THEMES_ADDONS=design-themes
THIRD_PARTY_ADDONS=vendor

# Odoo Runtime Configuration
ODOO_RC=config/<client>/dev.conf
PYTHONPATH=odoo:enterprise:design-themes

# Locale Settings (Peruvian Spanish)
LANG=es_PE.UTF-8
LC_ALL=es_PE.UTF-8
TZ=America/Lima
```

| Variable | Descripción | Nota |
|----------|-------------|------|
| `ENTERPRISE_ADDONS` / `THEMES_ADDONS` / `THIRD_PARTY_ADDONS` | Nombres de carpeta usados por `clone-addons.sh` | Default: `enterprise`, `design-themes`, `vendor` |
| `ODOO_RC` | Archivo de configuración Odoo | **Cambiar `<client>` por nombre del cliente** |
| `PYTHONPATH` | Rutas para imports Python | Odoo + Enterprise + Design Themes |
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

## Security Vulnerabilities and Mitigations

> **Última revisión:** Enero 2026

### Resumen de Vulnerabilidades por Python

> ⚠️ **Este repo es Odoo 16 → estás obligado a Python 3.10/3.11.** Subir a 3.12+ para
> reducir estos CVEs **no es opción en Odoo 16**: rompe el firmado EDI de SUNAT (pyOpenSSL 24
> eliminó `OpenSSL.crypto.sign`, ver Common Issues). La tabla siguiente describe el estado
> *por versión de Python en abstracto*; para **Odoo 16 la única fila viable es 3.10/3.11**,
> asumiendo sus CVEs y mitigándolos operativamente. El salto a 3.12 como mejora de seguridad
> aplica desde **Odoo 18.0+**.

| Python | Estado (abstracto) | Vulnerabilidades Abiertas | Odoo 16 |
|--------|--------|---------------------------|---------|
| 3.13+ | ✅ Menos CVEs | 1 (sin parche disponible) | ❌ Rompe EDI |
| 3.12 | ✅ Menos CVEs | 1 (sin parche disponible) | ❌ Rompe EDI |
| 3.10-3.11 | ⚠️ Más CVEs | 7+ (restricciones de Odoo) | ✅ **Única opción soportada** |

### CVEs Conocidos y Estado

| CVE | Paquete | Severidad | Parche | Python ≥3.12 | Python <3.12 |
|-----|---------|-----------|--------|--------------|--------------|
| CVE-2025-66471 | urllib3 | **High** | 2.6.0 | ✅ Corregido | ❌ Sin fix (1.x) |
| CVE-2025-66418 | urllib3 | **High** | 2.6.0 | ✅ Corregido | ❌ Sin fix (1.x) |
| CVE-2025-50181 | urllib3 | Medium | 2.5.0 | ✅ Corregido | ❌ Sin fix (1.x) |
| CVE-2024-12797 | cryptography | Low | 44.0.1 | ✅ Corregido | ❌ Sin fix (3.x) |
| CVE-2025-64512 | pdfminer.six | **High** | 20251107 | ✅ Corregido | ❌ Sin fix |
| CVE-2025-48994 | signxml | Medium | 4.0.4 | ✅ Corregido | ❌ Sin fix (3.x) |
| CVE-2025-48995 | signxml | Medium | 4.0.4 | ✅ Corregido | ❌ Sin fix (3.x) |
| GHSA-f83h | pdfminer.six | **High** | ❌ None | ⚠️ Sin parche | ⚠️ Sin parche |

### Vulnerabilidad sin Parche: pdfminer.six Pickle Deserialization

**GHSA-f83h-ghpp-7wcc** - Insecure Deserialization via pickle (CVSS 7.8 High)

**Descripción:** pdfminer.six usa `pickle` para cargar archivos CMap. Un atacante con acceso de escritura a directorios en `CMAP_PATH` puede ejecutar código arbitrario.

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

| Paquete | Versión Odoo | Limitación |
|---------|--------------|------------|
| cryptography | 3.4.8 | pyopenssl requiere esta versión |
| lxml | 4.x | Odoo no compatible con lxml 5.x |
| urllib3 | 1.x | requests de Odoo requiere 1.x |

**Consecuencia:** Vulnerabilidades en urllib3, signxml, pdfminer.six no pueden parchearse.

### Mitigaciones Recomendadas

| Acción | Impacto | Prioridad |
|--------|---------|-----------|
| **Usar Python ≥3.12** — ⚠️ **NO en Odoo 16** (rompe EDI); válido solo desde Odoo 18.0+ | Corrige 7 de 8 CVEs | 🔴 Alta (Odoo 18+) |
| Ejecutar Odoo como usuario sin privilegios | Limita escalación | 🔴 Alta |
| No configurar `CMAP_PATH` escribible | Mitiga pickle vuln | 🟡 Media |
| Firewall: limitar acceso a puertos Odoo | Reduce superficie | 🟡 Media |
| Monitorear pdfminer.six para parche | Preparar actualización | 🟢 Baja |

### Dependabot y Marcadores de Versión Python

Dependabot no interpreta los marcadores `python_version` en requirements.txt, por lo que muestra alertas aunque las vulnerabilidades estén corregidas para Python ≥3.12.

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

- [GHSA-f83h-ghpp-7wcc](https://github.com/pdfminer/pdfminer.six/security/advisories/GHSA-f83h-ghpp-7wcc) - pdfminer.six pickle
- [Dependabot Alerts](https://github.com/focuz-ai/odoo-env/security/dependabot) - Estado actual

## Peruvian Localization Modules

The environment is set up for Peruvian electronic invoicing and compliance:
- `l10n_pe_base`: EDI, partner extensions, POS, detractions
- `l10n_pe_accounting`: PLE books, SIRE with SUNAT API integration
- `l10n_pe_hr_payroll`: Payroll with PLAME, AFP, Renta 5ta

## Common Issues

**gevent build failure on Python 3.10**

```
Error compiling Cython file: src/gevent/libev/corecext.pyx:60:26: undeclared name not builtin: long
ERROR: Failed to build 'gevent' when getting requirements to build wheel
```

**Cause:** Odoo 16 pins `gevent==21.8.0`, which doesn't compile against modern setuptools/Cython
on Python 3.10. This is why **Python 3.11 is the recommended interpreter for this repo** (3.10
works but needs this workaround; 3.12+ is off the table because it breaks EDI signing — see
the pyOpenSSL entry below).

**Solution (only if Python 3.10 is required):**
```bash
pip install "setuptools<70" wheel "Cython<3"
pip install -r odoo/requirements.txt --no-build-isolation
pip install -r requirements.txt
```

**AttributeError: module 'OpenSSL.crypto' has no attribute 'sign' (Python ≥3.12 on Odoo 16)**

```
AttributeError: module 'OpenSSL.crypto' has no attribute 'sign'
```

**Cause:** On Python ≥3.12, `odoo/requirements.txt` pins `pyopenssl==24.1.0`. pyOpenSSL 24
**removed the module-level `OpenSSL.crypto.sign` / `verify` functions** (deprecated since 3.0).
The Peruvian EDI / SUNAT signing code (l10n_pe) still calls them, so digital signing crashes
at runtime. On Python 3.10/3.11 Odoo pins `pyopenssl==20.0.1`, which still provides them.

**Solution:** Use **Python 3.11** (or 3.10) for Odoo 16. Do not run Odoo 16 on Python 3.12+.
This is the same reason the version tables above mark 3.12/3.13 as ❌ for Odoo 16. The 3.12
upgrade path only becomes valid from Odoo 18.0+.

**Dependency conflicts on Python 3.10/3.11 (pandas build, cryptography, google-auth)**

Installing `requirements.txt` on Python 3.10/3.11 hits three chained issues, because the
markers fall back to the legacy dependency set:

1. `pandas==1.3.5` (sdist) fails to build with build isolation: `ModuleNotFoundError: No module
   named 'pkg_resources'` (setuptools ≥81 removed it, and the build overlay ignores the venv's).
2. `pip` silently upgrades `cryptography` 3.4.8 → latest via `pdfminer.six`, which then breaks
   `pyopenssl==20.0.1` at import (`AttributeError: module 'lib' has no attribute 'GEN_EMAIL'`).
3. `google-auth` (unpinned in the past) pulls ≥2.24, which requires `cryptography>=38.0.3`,
   conflicting with the mandatory `cryptography==3.4.8`.

**Solution:**
```bash
# Build deps for pandas 1.3.5 + keep pkg_resources available
pip install "setuptools<81" wheel "Cython<3" "numpy<2"
pip install --no-build-isolation -r requirements.txt
# Restore the cryptography version Odoo 16 requires on Python <3.12
pip install "cryptography==3.4.8"
pip check   # must report: No broken requirements found
```
`google-auth` is now pinned `<2.24` for `python_version < '3.12'` in `requirements.txt`, so
step 3 no longer recurs.

**InterfaceError: connection already closed**

Occurs when editing Python code while Odoo runs with auto-reload (`--dev=all` or
`--dev=...,reload,...`, e.g. the recommended `--dev=xml,reload,qweb`):
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

> **Note:** Use `max_cron_threads = 1` only when testing cron jobs, without `reload` in `--dev`.

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
