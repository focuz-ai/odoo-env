# docs/ — Estándares de desarrollo · Odoo **17.0** EE

**Única fuente de verdad** de los estándares de desarrollo para esta versión de Odoo
(17.0). Los agentes IA y los comandos del flujo Spec-Driven los consultan aquí; el
`CLAUDE.md` de este entorno referencia estos documentos en vez de duplicar reglas.

> Estructura estandarizada con la plantilla del sistema `odoo-openspec` (modelo
> *self-contained*: este `docs/` contiene el estándar **completo** de la versión 17.0).

## Índice

| Documento | Contenido |
|-----------|-----------|
| [conventions.md](conventions.md) | Estructura de módulo, manifest/licencia, orden de atributos, naming, herencia de vistas, XML, SCSS, i18n, datos/migración, calidad OCA |
| [orm-performance.md](orm-performance.md) | ORM correcto: N+1, `_read_group`, `@api.depends`/`precompute`, índices, SQL crudo (`odoo.tools.SQL`), transacciones/savepoints, excepciones |
| [security.md](security.md) | ACL/CSV, grupos, record rules, `check_access_rights`/`check_access_rule`, `sudo()`, multi-compañía, controladores, `consteq` |
| [frontend-owl.md](frontend-owl.md) | OWL 2, QWeb-JS, SCSS, assets/registry, widgets de campo (descriptor), `patch()`, QUnit |
| [testing.md](testing.md) | TransactionCase/HttpCase/`Form`/QUnit, perf (`assertQueryCount`), trazabilidad escenario→test, upgrade-safety |
| [git-guidelines.md](git-guidelines.md) | Formato de commit, tags, ramas, PR (guía oficial Odoo) |
| [submodule.md](submodule.md) | (Anexo operativo) Gestión de submódulos git y Fail2ban del entorno |

## Específico de Odoo 17.0
- Tests web: **QUnit** (`QUnit.module`/`QUnit.test`). **HOOT no existe en 17** (llegó en 18).
- Frontend: **OWL 2** (`@odoo/owl`). Sin bundles lazy (`web.assets_backend_lazy`/
  `web.assets_unit_tests` llegaron después).
- APIs de la serie: `check_access_rights()` + `check_access_rule()` (sin
  `check_access()` unificada), rutas JSON `type='json'` (no `jsonrpc`),
  `_sql_constraints` como lista de tuplas.
- `version` del manifest con formato **`17.0.x.y.z`**; `license` **`OPL-1`** y `author` **`"Focuz AI S.A.C."`** (siempre).
- Formato: estándar **OCA** (ruff/ruff-format, line-length **88**).
- Para APIs dudosas, verifica contra el fuente de **esta** versión (community/enterprise), de solo lectura.

## Fuentes oficiales
- Coding guidelines: https://www.odoo.com/documentation/17.0/contributing/development/coding_guidelines.html
- Git guidelines: https://www.odoo.com/documentation/17.0/contributing/development/git_guidelines.html
