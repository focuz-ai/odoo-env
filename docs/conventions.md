# Convenciones y arquitectura — Odoo 18.0 EE

> Fuente oficial: https://www.odoo.com/documentation/18.0/contributing/development/coding_guidelines.html

## Reúso primero
Antes de crear, busca en el fuente qué heredar o reutilizar: `_inherit`, `_inherits`,
o mixins (`mail.thread`, `mail.activity.mixin`, `portal.mixin`, `rating.mixin`,
`utm.mixin`). Extiende en lugar de duplicar. Sigue el mapa de reúso de la propuesta.

## Programación en Odoo (principios)
- **Pensar en extensible**: diseña para herencia/override. Llama a `super()`, divide
  en métodos pequeños y sobreescribibles, y no hardcodees lógica en métodos base que
  otros módulos puedan necesitar extender (refuerza «reúso primero»).
- **Propaga el contexto**: pasa/mezcla el `context` en las llamadas
  (`records.with_context(**extra).do_stuff()`) para preservar preferencias y entorno.
- SOLID/Clean Code en clave Odoo y anti-patrones (Repository/DDD/Service Layer):
  ver [engineering-principles.md](engineering-principles.md).
- Ver también en [orm-performance.md](orm-performance.md): nunca `commit()` manual,
  captura de excepciones específica e idioms de Python.

## Específico de Odoo 18
- Usa `@api.model_create_multi` en los `create` (no `@api.model`).
- Todo modelo requiere `_description`.
- Atributos booleanos de campo deben ser booleanos reales (`readonly=True`, no `readonly="True"`).
- Sin `_()` en las definiciones de `Selection` a nivel de clase (Odoo traduce solo).
- Los campos `related` no redefinen `selection`.
- Las `<i>` de FontAwesome requieren `title` por accesibilidad.
- Vista lista: etiqueta **`<list>`** (renombrada desde `<tree>` en 18.0); kanban con
  plantilla **`t-name="card"`** (antes `kanban-box`).

## Estructura del módulo
```
my_module/
├── __init__.py
├── __manifest__.py
├── data/                 # *_data.xml (noupdate donde el usuario edita)
├── demo/                 # solo datos demo (nunca en data/)
├── models/               # un archivo por modelo principal: sale_order.py
├── controllers/
├── wizard/               # TransientModel + sus vistas
├── security/             # ir.model.access.csv + *_groups.xml + *_security.xml
├── views/                # <modelo>_views.xml
├── report/               # *.py (SQL views) + *_templates.xml (QWeb)
├── static/
│   ├── description/icon.png
│   └── src/{js,scss,xml}/   # OWL 2, SCSS, plantillas QWeb-JS
├── migrations/<version>/    # scripts si cambia el esquema
├── tests/
└── i18n/                 # .pot / .po
```

## Manifest (`__manifest__.py`)
- `license`: **`OPL-1`** en módulos propios; se acepta **`LGPL-3`** (p.ej. módulos para
  OCA upstream). No OEEL-1 de EE.
- `author`: **`"Focuz AI S.A.C."`**; `website` de Focuz.
- `version`: **formato corto de Enterprise** (`<major>.<minor>[.<patch>]`, p.ej. `1.0`/`1.1`);
  sin prefijo de serie — Odoo antepone la serie al cargar (`1.1` → `18.0.1.1`).
  Ver §Versionado del módulo.
- `summary` corto (una línea); `category` adecuada; `installable: True`; `application` según el caso.
- `depends` completos (incluye dependencias EE reales).
- `data` en orden correcto: **security antes** de las vistas que lo usan.
- `assets` declarados en el bundle correcto (ver [frontend-owl.md](frontend-owl.md)).
- Datos demo en `demo`, nunca en `data`.

## Versionado del módulo (formato corto Enterprise) y changelog
El `version` usa el **formato corto de Enterprise**: `<major>.<minor>[.<patch>]` (sin
prefijo de serie; p.ej. `1.0`, `1.1`, `1.2.0`). Odoo le antepone la serie activa al
cargar (`1.1` → `18.0.1.1`). Se bumpea según el cambio:
- **major**: ruptura / cambio de esquema que requiere migración. Resetea minor(.patch) a 0.
- **minor**: feature nueva compatible. Resetea patch a 0.
- **patch**: corrección de bug, sin cambio de API ni esquema.
- **módulo nuevo**: arranca en `1.0`.

El bump va **en el mismo commit** del cambio (lo aplica `/odoo-commit`); el tag `[REL]`
se reserva para commits de release/milestone explícitos. **Alineación con migraciones**:
la carpeta de migración usa la versión **normalizada por Odoo** (serie + corto), p.ej.
manifest `1.1` → `migrations/18.0.1.1/`, y el manifest debe quedar `>=` esa versión para
que el script corra al actualizar.

Changelog (opcional, recomendado para módulos de cliente): `CHANGELOG.md` en la raíz del
módulo, estilo keep-a-changelog, una entrada por versión con fecha y ticket:
```markdown
## [1.1] - 2026-06-21
### Added
- <feature> (PROJ-123)
```
Secciones `Added`/`Changed`/`Fixed`/`Removed` ↔ tags `[ADD]`/`[IMP]`/`[FIX]`/`[REM]`.

## Cabecera y licencia de archivos
Cabecera de copyright + licencia en cada `.py` (estilo OCA, con la licencia y el autor
del proyecto). Sin `# -*- coding: utf-8 -*-` (innecesario en Python 3):
```python
# Copyright <año> Focuz AI S.A.C.
# License OPL-1 (https://www.odoo.com/documentation/user/legal/licenses.html#odoo-apps).
```

## Calidad y formato (capa de verificación EE — clon del repo `enterprise`)
> **Enforcement determinista**: estas reglas se *ejecutan* con los configs versionados
> del repo (`.ruff.toml`, `.pylintrc` + `.pylintrc-mandatory`, `.pre-commit-config.yaml`,
> `pyproject.toml`, `.editorconfig`, `prettier.config.cjs`, `eslint.config.cjs`,
> `checklog-odoo.cfg`) que `/odoo-init-repo` copia desde `scaffolding/`, más el gate
> `/odoo-verify-build` (instala + tests + cobertura). Este documento es la **única fuente
> de verdad del POR QUÉ**; los configs solo lo aplican. Si cambias una regla aquí,
> refléjala en el config (y al revés: la capa es un clon fiel del repo `enterprise`).

Convenciones OCA adoptadas, con las divergencias propias de un repo EE privado
(licencia/autor → OPL-1 / Focuz AI S.A.C.; longitud de línea EE):
- **Formato Python** (`.ruff.toml`): `ruff` + `ruff-format`; `isort` con secciones
  `stdlib → third-party → odoo → odoo.addons → first-party/local`; mccabe ≤ 16; reglas
  `E,F,W,B,C90,I,UP`; longitud de línea **120** (estándar EE focuz-ai: `enterprise` y
  `l10n-pe`; usa **88** solo en repos que se contribuyen a **OCA upstream**).
- **Lint Odoo** (`.pylintrc` + `.pylintrc-mandatory`): `pylint-odoo` en **dos niveles** —
  el `.pylintrc` carga opcionales + obligatorios (para el IDE); el `-mandatory` es el gate
  bloqueante de CI. Caza manifest/licencia (**OPL-1/LGPL-3**, author Focuz), XML, CSV,
  `.po`, SQLi, traducciones, depends/compute. `valid-odoo-versions` = `18.0`.
- **Seguridad** (`pyproject.toml` §`[tool.bandit]`): `bandit` sobre el código (no tests).
- **Formato XML/JS/SCSS/MD** (`prettier.config.cjs`): `prettier` + `@prettier/plugin-xml`,
  `printWidth` **120** (misma longitud de línea que el Python; el proyecto usa 120 de forma
  uniforme). `eslint` (`eslint.config.cjs`, flat config con globals Odoo) para JS si se activa.
- **pre-commit** (`.pre-commit-config.yaml`): higiene (`trailing-whitespace`,
  `end-of-file-fixer`, `check-xml/json/yaml/toml`…), `oca-checks-odoo-module` + `oca-checks-po`,
  `ruff`, `pylint-odoo` (2 pasos), `bandit`, `prettier`, y el commit-msg `[TAG] module:`.
  Versiones **pineadas** (ruff `v0.15.0`, pylint-odoo `v10.0.0`, OCA hooks `v0.2.20`,
  bandit `1.9.3`, pre-commit-hooks `v6.0.0`, prettier `3.6.2`).
- **CI** (`checklog-odoo.cfg`): gatea ERROR/CRITICAL en el log de Odoo tras instalar.
- **editorconfig**: indent 4 (`.py`/`.xml`), 2 (`.json`/`.yml`/`.rst`/`.md`), UTF-8,
  newline final, sin espacios finales.
- **Doc del módulo (OCA)**: fragmentos en `readme/` (`DESCRIPTION`, `USAGE`, `CONFIGURE`,
  `CONTRIBUTORS`) que generan `README.rst` (`oca-gen-addon-readme`). No usado por EE,
  pero no entra en conflicto.

## Organización de imports
```python
# 1. Stdlib primero, luego third-party
import base64
import logging
from datetime import datetime

# 2. Submódulos de Odoo
from odoo import api, fields, models, _
from odoo.exceptions import UserError, ValidationError
from odoo.tools import float_compare

# 3. Imports de addons (raro)
from odoo.addons.sale.models.sale_order import SaleOrder
```

## Estructura de modelos (orden de atributos)
1. Atributos privados (`_name`, `_description`, `_inherit`, `_order`).
2. `default`/`default_get`.
3. Declaración de campos.
4. `_sql_constraints` e índices.
5. Métodos compute/inverse/search (en el orden de los campos).
6. Métodos `_selection_*`.
7. `@api.constrains` y `@api.onchange`.
8. Overrides CRUD (`create`, `read`, `write`, `unlink`).
9. Métodos `action_*`.
10. Métodos de negocio (`_prepare_*`, etc.).

```python
class SaleOrder(models.Model):
    _name = 'sale.order'
    _description = 'Sales Order'
    _inherit = ['mail.thread', 'mail.activity.mixin']
    _order = 'date_order desc, id desc'

    name = fields.Char(string='Order Reference', required=True, copy=False)
    state = fields.Selection([
        ('draft', 'Quotation'),
        ('sale', 'Sales Order'),
        ('cancel', 'Cancelled'),
    ], string='Status', default='draft', tracking=True)
    amount_total = fields.Monetary(compute='_compute_amount', store=True)

    _sql_constraints = [
        ('name_uniq', 'unique(name, company_id)', 'Order reference must be unique!'),
    ]

    @api.depends('order_line_ids.price_subtotal')
    def _compute_amount(self):
        for order in self:
            order.amount_total = sum(order.order_line_ids.mapped('price_subtotal'))

    @api.model_create_multi
    def create(self, vals_list):
        for vals in vals_list:
            if not vals.get('name'):
                vals['name'] = self.env['ir.sequence'].next_by_code('sale.order')
        return super().create(vals_list)
```

## Naming
| Elemento | Convención | Ejemplo |
|----------|------------|---------|
| Modelo | singular, dot notation | `sale.order`, `res.partner` |
| Transient | `<modelo>.action` | `sale.order.make.invoice` |
| Report | `<modelo>.report.<action>` | `sale.report.order` |
| Variable modelo | PascalCase | `Partner`, `SaleOrder` |
| Variable record | snake_case | `partner`, `sale_order` |
| Many2one | sufijo `_id` | `partner_id` |
| X2many | sufijo `_ids` | `order_line_ids` |
| Compute | `_compute_<field>` | `_compute_amount_total` |
| Search | `_search_<field>` | `_search_product_id` |
| Default | `_default_<field>` | `_default_warehouse_id` |
| Selection | `_selection_<field>` | `_selection_state` |
| Onchange | `_onchange_<field>` | `_onchange_partner_id` |
| Constraint | `_check_<name>` | `_check_dates` |
| Action | `action_<verb>` | `action_confirm` |

Modelos y campos en `snake_case`; métodos privados con prefijo `_`.

## XML — IDs y herencia de vistas
```xml
<record id="sale_order_view_form" model="ir.ui.view">
    <field name="name">sale.order.form</field>
    <field name="model">sale.order</field>
    <field name="arch" type="xml"><form><!-- … --></form></field>
</record>
```
Naming de XML IDs: menús `<modelo>_menu`; vistas `<modelo>_view_<tipo>`; actions
`<modelo>_action`; grupos `<modulo>_group_<nombre>`; rules `<modelo>_rule_<grupo>`.

Herencia:
- Mismo `id` base + `name` `…form.inherit.<modulo>` + `inherit_id` correcto.
- Usa `xpath`/`position` (`after`/`before`/`inside`/`attributes`); evita `replace`
  frágil (rompe ante cambios upstream). No dupliques IDs.

## SCSS
- Prefijo obligatorio `o_<modulo>`; variables SCSS scoped (`$-padding`) y CSS vars
  para adaptaciones contextuales. Orden de propiedades: variables SCSS → CSS vars →
  position/layout → display → margin/width/border → padding/background → font/filter.
  No pises variables core de Odoo. Detalle en [frontend-owl.md](frontend-owl.md).

## Lógica y traducciones
- Lógica de negocio en los modelos, **nunca en las vistas**.
- Cadenas de cara al usuario envueltas en `_()` (server) / `_t` (web client). No
  concatenes cadenas traducibles; usa placeholders (`_("Hola %s", name)`).
- **Regenera el `.pot`** cuando añadas/cambies cadenas traducibles (no es opcional si las
  hay): export real, no a mano. En **Odoo 18** se usa el flag `--i18n-export`
  (el subcomando `i18n export` es de Odoo 19+):
  ```bash
  odoo-bin -c config/<cliente>/dev.conf -d <db> --modules=<modulo> \
    --i18n-export=<ruta_modulo>/i18n/<modulo>.pot --stop-after-init
  ```
  El `.pot` debe contener **todas** las cadenas `_()`/`_t` del módulo. Las `.po` por
  idioma se re-sincronizan desde el `.pot` actualizado (`msgmerge --update
  --no-fuzzy-matching --backup=none i18n/<lang>.po i18n/<modulo>.pot`).

  **Transición temporal — `.pot` no bloqueante en CI.** Mientras los repos terminan de
  estandarizar el export por versión, la CI reporta un `.pot` desactualizado como warning
  y notificación, pero no falla el build. Esto no rebaja el estándar: el
  `odoo-conventions-reviewer` debe reportarlo como hallazgo **medio** y el equipo debe
  corregirlo antes del release si el cambio añade o modifica cadenas traducibles.

## Datos y migración
- Registros editables por el usuario con `noupdate="1"`.
- Cambios de esquema → script en `migrations/<version>/` (ver [testing.md](testing.md)).

## Demo data
- Solo en `demo/` (nunca en `data/`); declarada en `demo` del manifest.
- **Debe cargar limpia**: instalar el módulo en una BD fresca con demo (lo que hace
  `/odoo-verify-build`) no puede fallar por la demo data. Datos demo rotos = build rojo.
- Realista y mínima: representa los casos de las specs (estados, multi-compañía,
  permisos) para que la demo sirva de base a tests `HttpCase`/tours y a la UAT.

## Permisos de archivo
Directorios `755`, archivos `644`.

## PEP8
PEP8 con **longitud de línea 120** (estándar EE focuz-ai; `E501` activo en `ruff`.
Usa 88 solo en repos destinados a OCA upstream); `E301`/`E302` (líneas en blanco)
relajadas.
