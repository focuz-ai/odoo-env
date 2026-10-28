# Frontend — OWL 2 y assets — Odoo 16.0 EE

## Componentes OWL 2 (`@odoo/owl`)
- `Component`, `useState`, `setup`, hooks; props **validados**.
- Nada de jQuery legacy nuevo; usa OWL + utilidades del web client.
- Plantillas QWeb-JS: `t-name`, `t-if`, `t-foreach` (con `t-key`), `t-on-*`, `t-att-*`.

## Registry y assets
- Registra en la categoría correcta:
  `registry.category("fields" | "view_widgets" | "services" | "actions" | ...)`.
- Para extender componentes existentes: `patch(Componente.prototype, "nombre", {...})`
  (`@web/core/utils/patch`; en 16 la firma lleva el **nombre del patch** como segundo
  argumento).
- Declara los assets en el bundle adecuado desde `__manifest__.py`:
  `web.assets_backend` (backend), `web.assets_frontend` (web público/portal),
  `web.assets_tests` (tours) y `web.qunit_suite_tests` (QUnit). En 16 **no existen**
  `web.assets_backend_lazy` ni `web.assets_unit_tests` (series posteriores).
- Respeta el orden de assets.

## Widgets de campo personalizados
- Componente OWL con `props = { ...standardFieldProps, ... }` y **estáticos sobre la
  clase**: `template`, `supportedTypes`, `extractProps`; se registra la clase
  directamente: `registry.category("fields").add("mi_widget", MyField)` (así
  `char_field.js` en 16; el descriptor-objeto `{ component, ... }` es de series
  posteriores — no aplica).
- **Frontera con backend**: el campo Python lo define el desarrollador backend; tú
  posees el componente OWL, su registro y los assets. El handoff es el
  `__manifest__.py`/registry.

## SCSS
- Prefijo obligatorio `o_<modulo>`; variables SCSS scoped y CSS vars para
  adaptaciones contextuales. No pises las variables core de Odoo.

## i18n
- Cadenas traducibles con el sistema del web client (`_t`).

## Tests del web client: QUnit (Odoo 16) — NO HOOT
Ver [testing.md](testing.md). En Odoo 16 el framework de tests web es **QUnit**
(`QUnit.module`, `QUnit.test`); **HOOT no existe en 16** (se introdujo en 18).
Consulta los helpers reales en el fuente (`addons/web/static/tests/helpers/`) antes
de escribir — no inventes APIs.
