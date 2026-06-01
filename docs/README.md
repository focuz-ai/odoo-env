# docs/ — Estándares de desarrollo · Odoo **18.0** EE

**Única fuente de verdad** de los estándares de desarrollo para esta versión de Odoo
(18.0). Los agentes IA y los comandos del flujo Spec-Driven los consultan aquí; el
`CLAUDE.md` de este entorno **referencia** estos documentos en vez de duplicar reglas.

> Estructura estandarizada con la plantilla del sistema `odoo-openspec` (modelo
> *self-contained*: este `docs/` contiene el estándar **completo** de la versión 18.0,
> sin depender de la plantilla global en runtime).

## Índice

| Documento | Contenido |
|-----------|-----------|
| [conventions.md](conventions.md) | Estructura de módulo, manifest/licencia, orden de atributos, naming, herencia de vistas, XML, SCSS, i18n, datos/migración, permisos de archivo |
| [orm-performance.md](orm-performance.md) | ORM correcto: N+1, `@api.depends`, índices, SQL, computes/constraints, transacciones/savepoints, excepciones |
| [security.md](security.md) | ACL/CSV, grupos, record rules, `sudo()`, multi-compañía, controladores |
| [frontend-owl.md](frontend-owl.md) | OWL 2, QWeb-JS, SCSS, assets/registry, widgets de campo, HOOT |
| [testing.md](testing.md) | TransactionCase/HttpCase/HOOT, trazabilidad escenario→test, upgrade-safety |
| [git-guidelines.md](git-guidelines.md) | Formato de commit, tags, ramas, PR (guía oficial Odoo) |
| [submodule.md](submodule.md) | (Anexo operativo) Gestión de submódulos git y Fail2ban del entorno |

## Específico de Odoo 18.0
- Tests web: **HOOT** (`@odoo/hoot`), **NO QUnit** (solo heredado en `static/tests/legacy/`).
- Frontend: **OWL 2** (`@odoo/owl`).
- `version` del manifest con formato **`18.0.x.y.z`**; `license` `OPL-1` (depende de EE) o `LGPL-3` (solo CE).
- Para APIs dudosas, verifica contra el fuente de **esta** versión (community/enterprise), de solo lectura.

## Fuentes oficiales
- Coding guidelines: https://www.odoo.com/documentation/18.0/contributing/development/coding_guidelines.html
- Git guidelines: https://www.odoo.com/documentation/18.0/contributing/development/git_guidelines.html
