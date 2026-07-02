# docs/ — Estándares de desarrollo · Odoo **16.0** EE

**Única fuente de verdad** de los estándares de desarrollo para esta versión de Odoo
(16.0). Los agentes IA y los comandos del flujo Spec-Driven los consultan aquí; el
`CLAUDE.md` de este entorno referencia estos documentos en vez de duplicar reglas.

> Estructura estandarizada con la plantilla del sistema `odoo-openspec` (modelo
> *self-contained*: este `docs/` contiene el estándar **completo** de la versión 16.0).

## Índice

| Documento | Contenido |
|-----------|-----------|
| [environment.md](environment.md) | Rutas del entorno, runtime, `odools.toml`, `dev.conf` y `launch.json` |
| [conventions.md](conventions.md) | Estructura de módulo, manifest/licencia, orden de atributos, naming, herencia de vistas, XML, SCSS, i18n, datos/migración, calidad OCA |
| [engineering-principles.md](engineering-principles.md) | SOLID y Clean Code en clave Odoo, manejo de errores, logging y anti-patrones |
| [orm-performance.md](orm-performance.md) | ORM correcto: N+1, `@api.depends`, índices, SQL, computes/constraints, transacciones/savepoints, excepciones |
| [security.md](security.md) | ACL/CSV, grupos, record rules, `sudo()`, multi-compañía, controladores |
| [frontend-owl.md](frontend-owl.md) | OWL 2, QWeb-JS, SCSS, assets/registry, widgets de campo, QUnit |
| [testing.md](testing.md) | TransactionCase/HttpCase/QUnit, trazabilidad escenario→test, upgrade-safety |
| [edi-integrations.md](edi-integrations.md) | EDI/autoridad fiscal: envío (`account.edi.format`), idempotencia, seguridad, auditoría y golden-files |
| [version-migration.md](version-migration.md) | Migrar el código de un módulo entre series: APIs, vistas, frontend, OpenUpgrade |
| [git-guidelines.md](git-guidelines.md) | Formato de commit, tags, ramas, PR (guía oficial Odoo) |

## Documentos relacionados (entorno)
- [dev-environment-optimization.md](dev-environment-optimization.md) — Postgres dev mode, `uv`, VSCode, Git, pytest-odoo, etc. (recomendaciones, no aplicadas aún en este repo).
- [submodule.md](submodule.md) — (Anexo operativo) Gestión de submódulos git y Fail2ban del entorno.

## Específico de Odoo 16.0
- Tests web: **QUnit** (`QUnit.module`/`QUnit.test`). **HOOT no existe en 16** (llegó en 18).
- Frontend: **OWL 2** (`@odoo/owl`).
- `version` del manifest con formato **`16.0.x.y.z`**; `license` **`OPL-1`** y `author` **`"Focuz AI S.A.C."`** (siempre).
- EDI: framework **`account.edi.format`** (módulo `account_edi`); **`account.move.send` no existe en 16** (es de Odoo 17+).
- Formato: estándar del proyecto (ruff/ruff-format, line-length **120** — ver `ruff.toml` en la raíz del entorno).
- Para APIs dudosas, verifica contra el fuente de **esta** versión (community/enterprise), de solo lectura.

## Fuentes oficiales
- Coding guidelines: https://www.odoo.com/documentation/16.0/contributing/development/coding_guidelines.html
- Git guidelines: https://www.odoo.com/documentation/16.0/contributing/development/git_guidelines.html
