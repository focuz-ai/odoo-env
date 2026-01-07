# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Odoo 18.0 development environment (o18-env) configured for multi-client/multi-project development with VSCode integration. It supports Odoo Community, Enterprise, and custom modules with a focus on Peruvian localization (l10n_pe).

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
└── .venv/             # Python 3.12 virtual environment
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
pip check
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

## Odoo Coding Guidelines

> **Fuente oficial:** https://www.odoo.com/documentation/master/contributing/development/coding_guidelines.html

### Odoo 18 Específico

- Use `@api.model_create_multi` instead of `@api.model` for create methods
- All models require `_description` attribute
- Boolean field attributes must be actual booleans (`readonly=True` not `readonly="True"`)
- No `_()` translation wrapper in class-level Selection field definitions
- Related fields don't need `selection` redefinition
- FontAwesome `<i>` tags require `title` attribute for accessibility

### Python - PEP8 con Excepciones

Odoo sigue PEP8 excepto:
- **E501:** Línea muy larga (permitido)
- **E301:** Expected 1 blank line (relajado)
- **E302:** Expected 2 blank lines (relajado)

### Organización de Imports

```python
# 1. Librerías externas (stdlib primero, luego third-party)
import base64
import logging
from datetime import datetime

# 2. Submódulos de Odoo
from odoo import api, fields, models, _
from odoo.exceptions import UserError, ValidationError
from odoo.tools import float_compare

# 3. Imports de addons (raramente usado)
from odoo.addons.sale.models.sale_order import SaleOrder
```

### Estructura de Modelos (Orden de Atributos)

```python
class SaleOrder(models.Model):
    # 1. Atributos privados
    _name = 'sale.order'
    _description = 'Sales Order'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _order = 'date_order desc, id desc'

    # 2. Métodos default y default_get
    @api.model
    def _default_warehouse_id(self):
        return self.env['stock.warehouse'].search([], limit=1)

    # 3. Declaración de campos
    name = fields.Char(string='Order Reference', required=True, copy=False)
    state = fields.Selection([
        ('draft', 'Quotation'),
        ('sent', 'Quotation Sent'),
        ('sale', 'Sales Order'),
        ('cancel', 'Cancelled'),
    ], string='Status', default='draft', tracking=True)
    partner_id = fields.Many2one('res.partner', string='Customer', required=True)
    order_line_ids = fields.One2many('sale.order.line', 'order_id', string='Order Lines')
    amount_total = fields.Monetary(compute='_compute_amount', store=True)

    # 4. Constraints SQL e índices
    _sql_constraints = [
        ('name_uniq', 'unique(name, company_id)', 'Order reference must be unique!'),
    ]

    # 5. Métodos compute, inverse, search (orden de campos)
    @api.depends('order_line_ids.price_subtotal')
    def _compute_amount(self):
        for order in self:
            order.amount_total = sum(order.order_line_ids.mapped('price_subtotal'))

    # 6. Métodos selection
    @api.model
    def _selection_state(self):
        return [('draft', 'Draft'), ('done', 'Done')]

    # 7. Constraints y onchange
    @api.constrains('partner_id')
    def _check_partner(self):
        for order in self:
            if order.partner_id.is_blocked:
                raise ValidationError(_('Partner is blocked!'))

    @api.onchange('partner_id')
    def _onchange_partner_id(self):
        if self.partner_id:
            self.pricelist_id = self.partner_id.property_product_pricelist

    # 8. Overrides CRUD (create, read, write, unlink)
    @api.model_create_multi
    def create(self, vals_list):
        for vals in vals_list:
            if not vals.get('name'):
                vals['name'] = self.env['ir.sequence'].next_by_code('sale.order')
        return super().create(vals_list)

    # 9. Métodos action
    def action_confirm(self):
        self.ensure_one()
        self.state = 'sale'
        return True

    # 10. Métodos de negocio
    def _prepare_invoice(self):
        self.ensure_one()
        return {
            'partner_id': self.partner_id.id,
            'origin': self.name,
        }
```

### Convenciones de Nombres

| Elemento | Convención | Ejemplo |
|----------|------------|---------|
| **Modelo** | Singular, dot notation | `sale.order`, `res.partner` |
| **Transient** | `<modelo>.action` | `sale.order.make.invoice` |
| **Report** | `<modelo>.report.<action>` | `sale.report.order` |
| **Variable modelo** | PascalCase | `Partner`, `SaleOrder` |
| **Variable record** | snake_case | `partner`, `sale_order` |
| **Campo Many2one** | Sufijo `_id` | `partner_id`, `order_id` |
| **Campo X2many** | Sufijo `_ids` | `order_line_ids`, `tag_ids` |
| **Método compute** | `_compute_<field>` | `_compute_amount_total` |
| **Método search** | `_search_<field>` | `_search_product_id` |
| **Método default** | `_default_<field>` | `_default_warehouse_id` |
| **Método selection** | `_selection_<field>` | `_selection_state` |
| **Método onchange** | `_onchange_<field>` | `_onchange_partner_id` |
| **Método constraint** | `_check_<name>` | `_check_dates` |
| **Método action** | `action_<verb>` | `action_confirm`, `action_cancel` |

### Buenas Prácticas Python

```python
# ✅ Crear diccionarios con literales
my_dict = {'foo': 3, 'bar': 4}

# ❌ Evitar .clone()
new_dict = my_dict.clone()  # Mal
new_dict = dict(my_dict)    # Bien

# ✅ Actualizar diccionarios
my_dict.update(foo=3, bar=4)
my_dict.setdefault('key', default_value)

# ✅ Colecciones como booleanos
if collection:      # Bien
if len(collection): # Mal

# ✅ Iterar diccionarios
for key in my_dict:           # Bien (keys)
for key, value in my_dict.items():  # Bien (items)
for key in my_dict.keys():    # Innecesario

# ✅ Usar context correctamente
records.with_context(new_context).do_stuff()  # Reemplaza contexto
records.with_context(**extra).do_stuff()      # Merge contexto
```

### Traducciones con `_()`

```python
# ✅ Correcto - string literal con parámetros
error = _('Record %s cannot be modified!', record.name)
message = _('Hello %(name)s!', name=user.name)

# ❌ Incorrecto - formateo fuera de _()
error = _('Record %s!') % record.name
error = _('Record ' + name + '!')

# ❌ Incorrecto - en definición de Selection a nivel clase
state = fields.Selection([
    ('draft', _('Draft')),  # MAL - no usar _() aquí
])

# ✅ Correcto - Selection sin _()
state = fields.Selection([
    ('draft', 'Draft'),     # BIEN - Odoo traduce automáticamente
])
```

### Transacciones y Savepoints

```python
# ❌ NUNCA hacer commit manual
self.env.cr.commit()  # PROHIBIDO

# ✅ Usar savepoints para aislar excepciones
try:
    with self.env.cr.savepoint():
        do_risky_stuff()
except SpecificException:
    # La transacción principal no se corrompe
    handle_error()

# ⚠️ Máximo ~64 savepoints por transacción (límite PostgreSQL)
```

### Excepciones

```python
# ❌ Evitar catch genérico
try:
    do_something()
except Exception as e:
    logger.warning(e)

# ✅ Capturar excepciones específicas
try:
    do_something()
except ValidationError:
    # Manejar específicamente
    pass
except UserError as e:
    # Manejar diferente
    raise UserError(_('Error: %s', e))
```

### Estructura de Módulo

```
my_module/
├── __init__.py
├── __manifest__.py
├── data/
│   ├── my_module_data.xml      # Datos iniciales
│   └── my_module_demo.xml      # Datos demo
├── models/
│   ├── __init__.py
│   ├── sale_order.py           # Un archivo por modelo principal
│   └── res_partner.py
├── views/
│   ├── sale_order_views.xml    # <modelo>_views.xml
│   └── res_partner_views.xml
├── security/
│   ├── ir.model.access.csv     # Permisos CRUD
│   ├── my_module_groups.xml    # Grupos de usuarios
│   └── sale_order_security.xml # Record rules
├── wizard/
│   ├── __init__.py
│   ├── sale_make_invoice.py
│   └── sale_make_invoice_views.xml
├── report/
│   ├── sale_report.py          # SQL views
│   └── sale_report_templates.xml
├── controllers/
│   └── my_module.py            # HTTP routes
├── static/
│   ├── description/
│   │   └── icon.png
│   └── src/
│       ├── js/
│       ├── scss/
│       └── xml/
└── tests/
    ├── __init__.py
    └── test_sale_order.py
```

### XML - IDs y Vistas

```xml
<!-- Formato: name antes de model, id al inicio -->
<record id="sale_order_view_form" model="ir.ui.view">
    <field name="name">sale.order.form</field>
    <field name="model">sale.order</field>
    <field name="arch" type="xml">
        <form>
            <!-- contenido -->
        </form>
    </field>
</record>

<!-- Naming de XML IDs -->
<!-- Menús: <modelo>_menu -->
<menuitem id="sale_order_menu" name="Sales Orders"/>

<!-- Vistas: <modelo>_view_<tipo> -->
<record id="sale_order_view_form" model="ir.ui.view"/>
<record id="sale_order_view_tree" model="ir.ui.view"/>
<record id="sale_order_view_kanban" model="ir.ui.view"/>

<!-- Actions: <modelo>_action -->
<record id="sale_order_action" model="ir.actions.act_window"/>

<!-- Grupos: <modulo>_group_<nombre> -->
<record id="sale_group_manager" model="res.groups"/>

<!-- Rules: <modelo>_rule_<grupo> -->
<record id="sale_order_rule_user" model="ir.rule"/>

<!-- Herencia: mismo ID + .inherit en name -->
<record id="sale_order_view_form" model="ir.ui.view">
    <field name="name">sale.order.form.inherit.my_module</field>
    <field name="inherit_id" ref="sale.sale_order_view_form"/>
</record>
```

### CSS/SCSS Convenciones

```scss
// Prefijo obligatorio: o_<modulo>
.o_sale_order_form {
    // Variables SCSS scoped (block-level)
    $-padding: 10px;

    padding: $-padding;

    .o_sale_order_header {
        // CSS variables para adaptaciones contextuales
        color: var(--SaleOrder-header-color, #{$o-sale-header-color});
    }
}

// Orden de propiedades:
// 1. Variables SCSS scoped
// 2. CSS variables
// 3. Position/layout
// 4. Display
// 5. Margin, width, border
// 6. Padding, background
// 7. Font, filter
```

### Permisos de Archivos

| Tipo | Permiso |
|------|---------|
| Directorios | 755 |
| Archivos | 644 |

## Odoo Git Guidelines

> **Fuente oficial:** https://www.odoo.com/documentation/master/contributing/development/git_guidelines.html

### Formato de Mensaje de Commit

```
[TAG] module: short description (ideally < 50 chars)

Long description explaining WHY the change was made,
including rationale and technical decisions.

References: task-123, Fixes #123, opw-123
```

**Principios clave:**
- **Enfócate en el POR QUÉ, no en el QUÉ** - El diff muestra qué cambió, el mensaje debe explicar por qué
- **El header debe formar una oración válida:** "if applied, this commit will [header]"
- **Un módulo por commit** - Evita commits que impacten múltiples módulos (para permitir reverts independientes)
- **Usa nombres técnicos** - Nombres de módulos técnicos, no funcionales

### Tags de Commit (Prefijos)

| Tag | Uso | Ejemplo |
|-----|-----|---------|
| `[FIX]` | Bug fixes (stable o desarrollo reciente) | `[FIX] sale: correct discount calculation` |
| `[IMP]` | Mejoras incrementales (más común) | `[IMP] stock: add batch picking support` |
| `[ADD]` | Nuevos módulos | `[ADD] l10n_pe_edi: Peruvian electronic invoicing` |
| `[REF]` | Refactoring de features | `[REF] account: split invoice logic into mixins` |
| `[REM]` | Eliminar código muerto, vistas o módulos | `[REM] sale: remove deprecated workflow` |
| `[REV]` | Revertir commits | `[REV] stock: revert batch changes (breaks X)` |
| `[MOV]` | Mover archivos (preserva historial git) | `[MOV] web: move static assets to new structure` |
| `[REL]` | Commits de release (major/minor) | `[REL] 18.0` |
| `[MERGE]` | Merge commits y forward ports | `[MERGE] 17.0 into 18.0` |
| `[CLA]` | Firma de Contributor License Agreement | `[CLA] sign individual CLA` |
| `[I18N]` | Cambios en archivos de traducción | `[I18N] l10n_pe: update Spanish translations` |
| `[PERF]` | Mejoras de performance | `[PERF] stock: optimize quant queries` |
| `[CLN]` | Limpieza de código | `[CLN] sale: remove unused imports` |
| `[LINT]` | Pasadas de linting | `[LINT] account: fix pylint warnings` |

### Nombrado de Branches

```bash
# Formato: <base-branch>-<descripcion>
18.0-fix-invoice-discount
18.0-add-batch-picking
master-improve-stock-valuation

# Para empleados de Odoo, agregar handle:
18.0-fix-invoice-discount-abc
```

### Ejemplos de Buenos Commits

**Bug fix:**
```
[FIX] sale: correct discount calculation on multi-line orders

When applying a global discount to orders with multiple lines,
the discount was being applied twice to lines with quantity > 1.

This was caused by the discount computation being called both
in _compute_amount and in the line's _compute_discount method.

The fix moves all discount logic to _compute_amount to ensure
single computation.

Fixes #12345
```

**Mejora:**
```
[IMP] stock: add batch transfer support for warehouse operations

Large warehouses need to process multiple transfers simultaneously
to improve picking efficiency. This adds:
- Batch transfer model to group pickings
- Batch picking wizard
- Batch validation with partial support

task-456789
```

**Nuevo módulo:**
```
[ADD] l10n_pe_edi: Peruvian electronic invoicing module

Adds support for SUNAT electronic documents:
- Factura electrónica (invoice)
- Boleta electrónica (ticket)
- Nota de crédito/débito
- Guía de remisión

Includes UBL 2.1 XML generation and SOAP web service integration.
```

### PR Guidelines

1. **Base branch:** Usar `master` para nuevas features, `X.0` para bug fixes
2. **Título del PR:** Mismo formato que el commit principal
3. **Descripción:** Incluir contexto, screenshots si aplica, y pasos de testing
4. **CLA:** Firmar el CLA antes de contribuir (doc/cla/individual/)
5. **Allow edits:** Habilitar "Allow edits from maintainer"

### Git Config Recomendado

```bash
# Configurar identidad
git config --global user.name "Harrison Chumpitaz"
git config --global user.email "hchumpitaz92@gmail.com"

# Configurar remotes para contribuir
git remote add upstream https://github.com/odoo/odoo.git
git remote add origin https://github.com/focuz-ai/odoo.git
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

## Security Vulnerabilities and Mitigations

> **Última revisión:** Enero 2026

### Resumen de Vulnerabilidades por Python

| Python | Estado | Vulnerabilidades Abiertas |
|--------|--------|---------------------------|
| 3.13+ | ✅ **Recomendado** | 1 (sin parche disponible) |
| 3.12 | ✅ Seguro | 1 (sin parche disponible) |
| 3.10-3.11 | ⚠️ **No recomendado** | 7+ (restricciones de Odoo) |

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
| **Usar Python ≥3.12** | Corrige 7 de 8 CVEs | 🔴 Alta |
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
