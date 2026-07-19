# Frontend — OWL 2 y assets — Odoo 17.0 EE

## Componentes OWL 2 (`@odoo/owl`)
- `Component`, `useState`, `setup`, hooks; props **validados**.
- Nada de jQuery legacy nuevo; usa OWL + utilidades del web client.
- Plantillas QWeb-JS: `t-name`, `t-if`, `t-foreach` (con `t-key`), `t-on-*`, `t-att-*`.

## Registry y assets
- Registra en la categoría correcta:
  `registry.category("fields" | "view_widgets" | "services" | "actions" | ...)`.
- Declara los assets en el bundle adecuado desde `__manifest__.py`:
  `web.assets_backend` (backend), `web.assets_frontend` (web público/portal),
  `web.qunit_suite_tests` (tests QUnit), `web.assets_tests` (pasos de tours).
- **No existen bundles lazy en 17** (`web.assets_backend_lazy`,
  `web.assets_unit_tests` llegaron después); no los declares.
- Respeta el orden de assets.

## Widgets de campo personalizados
- Patrón dominante del fuente 17: **extiende un componente de campo existente**
  (p.ej. `CharField`) y registra un **objeto descriptor** en
  `registry.category("fields")`:
  ```js
  export const myField = {
      component: MyField,
      displayName: _t("My Field"),
      supportedTypes: ["char"],
      extractProps: ({ options }) => ({ ... }),
  };
  registry.category("fields").add("my_widget", myField);
  ```
  `standardFieldProps` existe para validar las props estándar del componente.
- Para modificar comportamiento de componentes/servicios existentes sin
  reemplazarlos: `patch(objeto, extensión)` de `@web/core/utils/patch`
  (dos argumentos en 17; llama a `super.…` en los overrides).
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
