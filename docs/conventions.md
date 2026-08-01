# Convenciones y arquitectura — Odoo 19.0 EE

> Fuente oficial: https://www.odoo.com/documentation/master/contributing/development/coding_guidelines.html

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
- Ver también en [orm-performance.md](orm-performance.md): nunca `commit()` manual,
  captura de excepciones específica e idioms de Python.

## Específico de Odoo 19
- Usa `@api.model_create_multi` en los `create` (no `@api.model`).
- Todo modelo requiere `_description`.
- Constraints SQL como **atributo de clase `models.Constraint`** — `_sql_constraints`
  está muerto en 19 (0 usos en el fuente):
  `_name_uniq = models.Constraint('unique (name)', "A tag with the same name already exists.")`
  (cf. `helpdesk/models/helpdesk_tag.py`, `planning/models/planning_slot.py`).
- Atributos booleanos de campo deben ser booleanos reales (`readonly=True`, no `readonly="True"`).
- Sin `_()` en las definiciones de `Selection` a nivel de clase (Odoo traduce solo).
- Los campos `related` no redefinen `selection`.
- Las `<i>` de FontAwesome requieren `title` por accesibilidad.

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
- `license`: **`OPL-1`** siempre (estándar del proyecto; no AGPL/LGPL de OCA ni OEEL-1 de EE).
- `author`: **`"Focuz AI S.A.C."`**; `website` de Focuz.
- `version` con formato **`19.0.x.y.z`**.
- `summary` corto (una línea); `category` adecuada; `installable: True`; `application` según el caso.
- `depends` completos (incluye dependencias EE reales).
- `auto_install` acepta **lista de dependencias-gatillo** para módulos-unión:
  `'auto_install': ['l10n_pe']` (cf. `l10n_pe_edi`) — es el patrón de glue-module
  del fuente; no existen módulos `*_bridge`.
- `sequence` cuando el módulo es una app con menú propio (orden en el home de apps).
- `data` en orden correcto: **security antes** de las vistas que lo usan.
- `assets` declarados en el bundle correcto (ver [frontend-owl.md](frontend-owl.md)).
- Datos demo en `demo`, nunca en `data`.

## Cabecera y licencia de archivos
Cabecera de copyright + licencia en cada `.py` (estilo OCA, con la licencia y el autor
del proyecto). Sin `# -*- coding: utf-8 -*-` (innecesario en Python 3):
```python
# Copyright <año> Focuz AI S.A.C.
# License OPL-1 (https://www.odoo.com/documentation/user/legal/licenses.html#odoo-apps).
```

## Calidad y formato (capa de verificación EE)
> Estas reglas se ejecutan con configs versionados y con el gate de verificación del
> repo. Este documento explica el POR QUÉ; el scaffold aplica el CÓMO.

- **Formato**: `ruff` + `ruff-format`; `isort` con secciones
  `stdlib → third-party → odoo → odoo.addons → first-party/local`; mccabe ≤ 16;
  longitud de línea **120**.
- **Lint Odoo**: `pylint-odoo` (manifest, XML, CSV, `.po`).
- **Seguridad**: `bandit` sobre el código.
- **Pre-commit**: higiene básica, `ruff`, `pylint-odoo`, `bandit`, `prettier` y
  commit-msg con `[TAG] module:`.
- **editorconfig**: indent 4 (`.py`/`.xml`), 2 (`.json`/`.yml`/`.rst`/`.md`), UTF-8,
  newline final, sin espacios finales.
- **Doc del módulo (OCA)**: fragmentos en `readme/` (`DESCRIPTION`, `USAGE`, `CONFIGURE`,
  `CONTRIBUTORS`) que generan `README.rst` (`oca-gen-addon-readme`). No usado por EE,
  pero sin conflicto.

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
4. Constraints SQL (`models.Constraint`) e índices.
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

    _name_uniq = models.Constraint(
        'unique (name, company_id)',
        'Order reference must be unique!',
    )

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
- Usa `xpath`/`position` (`after`/`before`/`inside`/`attributes`); `position="move"`
  reordena un nodo existente sin re-declararlo. Prefiere `attributes`/`after`/`before`;
  `replace` es legítimo cuando sustituyes un bloque completo (el fuente lo usa a
  gran escala), pero exige re-sincronizar ante cambios upstream — úsalo con juicio,
  no por comodidad. No dupliques IDs.

## SCSS
- Prefijo obligatorio `o_<modulo>`; variables SCSS scoped (`$-padding`) y CSS vars
  para adaptaciones contextuales. Orden de propiedades: variables SCSS → CSS vars →
  position/layout → display → margin/width/border → padding/background → font/filter.
  No pises variables core de Odoo. Detalle en [frontend-owl.md](frontend-owl.md).

## Lógica y traducciones
- Lógica de negocio en los modelos, **nunca en las vistas**.
- Cadenas de cara al usuario con `_()` (server) / `_t` (web client). No concatenes
  cadenas traducibles; usa parámetros: `_('Record %s!', record.name)`. Regenera `.pot`.
- Locale canónico para PE: **`es_419`** — todos los módulos `l10n_pe_*` del fuente
  publican solo `i18n/es_419.po`. No crees `es_PE.po`.

> **Transición temporal — `.pot` no bloqueante en CI.** Mientras el export de i18n por
> serie se termina de estandarizar en los repos, un `.pot` desactualizado se reporta
> como warning y documentación, pero no bloquea el build. El estándar sigue vigente y
> debe corregirse antes de release si el cambio añade o modifica cadenas traducibles.

## Datos y migración
- Registros editables por el usuario con `noupdate="1"`.
- Cambios de esquema → script en `migrations/<version>/` con la **versión corta** del
  manifest, p.ej. `migrations/1.1/` (ver [version-migration.md](version-migration.md)).

## Permisos de archivo
Directorios `755`, archivos `644`.

## PEP8
PEP8 con **longitud de línea 120** (`E501` activo en `ruff`, no 79); `E301`/`E302`
(líneas en blanco) relajadas.
