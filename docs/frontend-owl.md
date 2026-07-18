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
- Cadenas traducibles con el sistema del web client (`_t`); regenera el `.pot`
  (ver [conventions.md](conventions.md) §Lógica y traducciones).

## Accesibilidad (a11y)
- **HTML semántico**: `<button>` para acciones (no `<div t-on-click>`), encabezados y
  listas reales; reutiliza los componentes accesibles del web client antes de crear uno.
- **Teclado**: todo lo operable con ratón debe serlo con teclado (foco visible, `Tab`,
  `Enter`/`Esc`); gestiona el foco al abrir/cerrar diálogos.
- **ARIA y etiquetas**: `aria-label`/`aria-labelledby` en controles sin texto visible;
  `role`/`aria-expanded`/`aria-selected` donde el patrón lo pida; los iconos decorativos
  con `aria-hidden`.
- **No solo color**: estados (error/éxito) con texto o icono además del color; respeta
  el contraste de los temas Odoo (no pises variables core).

## Tests: HOOT (Odoo 18) — NO QUnit
Ver [testing.md](testing.md). En Odoo 18 el framework web es **HOOT**
(`@odoo/hoot`, `@odoo/hoot-dom`, `@odoo/hoot-mock`). QUnit solo existe en código
heredado bajo `static/tests/legacy/`. Consulta los helpers reales en el fuente
(`odoo/addons/web/static/tests/`) antes de escribir — no inventes APIs.
