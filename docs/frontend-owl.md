# Frontend — OWL 2 y assets — Odoo 17.0 EE

## Componentes OWL 2 (`@odoo/owl`)
- `Component`, `useState`, `setup`, hooks; props **validados**.
- Nada de jQuery legacy nuevo; usa OWL + utilidades del web client.
- Plantillas QWeb-JS: `t-name`, `t-if`, `t-foreach` (con `t-key`), `t-on-*`, `t-att-*`.

## Registry y assets
- Registra en la categoría correcta:
  `registry.category("fields" | "view_widgets" | "services" | "actions" | ...)`.
- Declara los assets en el bundle adecuado desde `__manifest__.py`:
  `web.assets_backend` (backend), `web.assets_frontend` (web público/portal).
- Respeta el orden de assets.

## Widgets de campo personalizados
- Extiende `standardFieldProps` y registra en `registry.category("fields")`.
- **Frontera con backend**: el campo Python lo define el desarrollador backend; tú
  posees el componente OWL, su registro y los assets. El handoff es el
  `__manifest__.py`/registry.

## SCSS
- Prefijo obligatorio `o_<modulo>`; variables SCSS scoped y CSS vars para
  adaptaciones contextuales. No pises las variables core de Odoo.

## i18n
- Cadenas traducibles con el sistema del web client (`_t`).

## Tests del web client: QUnit (Odoo 17) — NO HOOT
Ver [testing.md](testing.md). En Odoo 17 el framework de tests web es **QUnit**
(`QUnit.module`, `QUnit.test`); **HOOT no existe en 17** (se introdujo en 18).
Consulta los helpers reales en el fuente (`addons/web/static/tests/helpers/`) antes
de escribir — no inventes APIs.
