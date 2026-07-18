# docs/ — Estándares de desarrollo · Odoo **18.0** EE

**Única fuente de verdad** de los estándares de desarrollo para esta versión de Odoo
(18.0). Los agentes IA y los comandos del flujo Spec-Driven los consultan aquí; el
`CLAUDE.md` de este entorno **referencia** estos documentos en vez de duplicar reglas.

> Estructura estandarizada con la plantilla del sistema `odoo-openspec` (modelo
> *self-contained*: este `docs/` contiene el estándar **completo** de la versión 18.0,
> sin depender de la plantilla global en runtime). Lo version-agnóstico del sistema
> (loop engineering, clasificación de riesgo, calidad de specs) vive en la plantilla,
> no aquí.

## Índice

| Documento | Contenido |
|-----------|-----------|
| [conventions.md](conventions.md) | Estructura de módulo, manifest/licencia/versionado, orden de atributos, naming, XML, SCSS, i18n, datos/demo/migración, capa de verificación determinista |
| [engineering-principles.md](engineering-principles.md) | SOLID y Clean Code en clave Odoo (SRP/OCP/DRY/ISP, métodos pequeños, errores, logging) y anti-patrones (DDD/Repository/capas) |
| [orm-performance.md](orm-performance.md) | ORM correcto: N+1, `@api.depends`, índices, `assertQueryCount`, SQL, computes/constraints, transacciones/savepoints, excepciones |
| [security.md](security.md) | ACL/CSV, grupos, record rules, `sudo()`, multi-compañía, controladores, adjuntos |
| [frontend-owl.md](frontend-owl.md) | OWL 2, QWeb-JS, SCSS, assets/registry, widgets de campo, a11y, HOOT |
| [testing.md](testing.md) | TransactionCase/HttpCase/HOOT, trazabilidad escenario→test, tests de integridad (no tautológicos), golden-file, cobertura, upgrade-safety |
| [edi-integrations.md](edi-integrations.md) | EDI/autoridad fiscal: `account.move.send`, deconflicción, firma, idempotencia, `neutralize.sql`, golden-file |
| [version-migration.md](version-migration.md) | Migrar el código de un módulo a la serie 18.0: APIs deprecadas, vistas `<list>`, HOOT, OpenUpgrade |
| [git-guidelines.md](git-guidelines.md) | Formato de commit, tags, ramas `tmp.<serie>`/staging, PR y CI (estilo Odoo) |
| [submodule.md](submodule.md) | (Anexo operativo) Gestión de submódulos git y Fail2ban del entorno |

## Específico de Odoo 18.0
- Tests web: **HOOT** (`@odoo/hoot`), **NO QUnit** (solo heredado en `static/tests/legacy/`).
- Frontend: **OWL 2** (`@odoo/owl`).
- Vistas: lista con etiqueta **`<list>`** (no `<tree>`); kanban con `t-name="card"`.
- `version` del manifest en **formato corto Enterprise** (`1.0`, `1.1`…; Odoo antepone
  `18.0` al cargar); `license` **`OPL-1`** (o `LGPL-3` para OCA upstream) y `author`
  **`"Focuz AI S.A.C."`**.
- Export de i18n con `--i18n-export` (el subcomando `i18n export` es de Odoo 19+).
- Para APIs dudosas, verifica contra el fuente de **esta** versión (community/enterprise), de solo lectura.

## Fuentes oficiales
- Coding guidelines: https://www.odoo.com/documentation/18.0/contributing/development/coding_guidelines.html
- Git guidelines: https://www.odoo.com/documentation/18.0/contributing/development/git_guidelines.html
