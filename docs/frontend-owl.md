# Frontend — OWL 2 y assets — Odoo 18.0 EE

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
- Prefijo obligatorio `o_<modulo>`:
```scss
.o_sale_order_form {
    $-padding: 10px;                 // 1. variables SCSS scoped
    color: var(--SaleOrder-color);   // 2. CSS variables
    padding: $-padding;              // 3+. layout, display, box, font…
}
```
- Orden de propiedades: variables SCSS scoped → CSS variables → position/layout →
  display → margin/width/border → padding/background → font/filter.
- No pises las variables core de Odoo.

## i18n
- Cadenas traducibles con el sistema del web client (`_t`).

## Tests: HOOT (Odoo 18) — NO QUnit
Ver [testing.md](testing.md). En Odoo 18 el framework web es **HOOT**
(`@odoo/hoot`, `@odoo/hoot-dom`, `@odoo/hoot-mock`). QUnit solo existe en código
heredado bajo `static/tests/legacy/`. Consulta los helpers reales en el fuente
(`odoo/addons/web/static/tests/`) antes de escribir — no inventes APIs.
