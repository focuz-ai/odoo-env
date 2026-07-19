# Frontend — OWL 2 y assets — Odoo 19.0 EE

## Componentes OWL 2 (`@odoo/owl`)
- `Component`, `useState`, `setup`, hooks; props **validados**.
- Nada de jQuery legacy nuevo; usa OWL + utilidades del web client.
- Plantillas QWeb-JS: `t-name`, `t-if`, `t-foreach` (con `t-key`), `t-on-*`, `t-att-*`.
- Herencia de plantillas: `t-inherit="modulo.Plantilla"` + `t-inherit-mode` con
  `xpath`. No escribas `owl="1"` (extinto en 19).

## Extensión del web client
- `patch()` de `@web/core/utils/patch` es el mecanismo estándar para extender
  componentes/servicios existentes (el más usado del fuente).
- Estado compartido vía `useService(...)`, no estado local duplicado; un servicio
  propio es un objeto `{dependencies: [...], start(env, deps) {...}}` registrado en
  `registry.category("services")`.

## Registry y assets
- Registra en la categoría correcta:
  `registry.category("fields" | "views" | "view_widgets" | "services" | "actions" | ...)`.
- Vista nueva en `views` = **descriptor MVC por spread** de la vista base:
  `{...ganttView, Controller: MiController, Renderer: MiRenderer, Model: MiModel}`
  (cf. `planning/static/src/views/planning_gantt/planning_gantt_view.js`).
- Declara los assets en el bundle adecuado desde `__manifest__.py`:
  `web.assets_backend` (backend), `web.assets_frontend` (web público/portal),
  `web.assets_backend_lazy` para vistas secundarias pesadas (patrón
  `("remove", ...)` del bundle principal + re-add en el lazy).
- SCSS de tema: variables `*.variables.scss` con `!default` van en
  `web._assets_primary_variables`; las variantes dark en `*.dark.scss` dentro de los
  bundles dark (`web.dark_mode_variables`, `*_dark`).
- Respeta el orden de assets.

## Widgets de campo personalizados
- Extiende un componente de campo existente (`X2ManyField`, `CharField`, ...) con
  spread de sus `static props`, y registra un **objeto descriptor** en
  `registry.category("fields")` — nunca el componente pelado
  (cf. `sign/static/src/fields/signer_x2many.js`):
```js
export const signerX2Many = {
    component: SignerX2Many,
    displayName: _t("Signer One 2 Many"),
    supportedTypes: ["one2many"],
    relatedFields: () => [...],      // campos extra que el widget necesita
    fieldDependencies: [...],
    extractProps: x2ManyField.extractProps,
};
registry.category("fields").add("signer_x2many", signerX2Many);
```
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
- Regenera `.pot` cuando cambies texto de UI.

## Accesibilidad

- Usa HTML semántico.
- Asegura navegación por teclado.
- No dependas solo del color para estados.

## Tests: HOOT (Odoo 19) — NO QUnit
Ver [testing.md](testing.md). En Odoo 19 el framework web es **HOOT**
(`@odoo/hoot`, `@odoo/hoot-dom`, `@odoo/hoot-mock`). QUnit solo existe en código
heredado bajo `static/tests/legacy/`. Consulta los helpers reales en el fuente
(`odoo/addons/web/static/tests/`) antes de escribir — no inventes APIs.
