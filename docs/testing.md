# Tests, trazabilidad y upgrade-safety — Odoo 16.0 EE

## Trazabilidad escenario → test
- **Cada `#### Scenario` de las specs debe tener un test** que lo ejercite.
- El reviewer empieza siempre por la tabla escenario → test (cubierto / hueco).

## Desarrollo por tarea con gates
- Cada tarea debe dejar evidencia proporcional antes de marcarse como hecha.
- Si el módulo todavía no es instalable, registra un gate parcial.
- El gate completo sigue siendo instalación + tests + cobertura.
- Usa `--test-tags` para focalizar cuando haga falta.

## Tipo de test correcto
| Escenario | Test |
|-----------|------|
| Lógica de servidor (modelos, computes, constraints, permisos, estados) | `TransactionCase` |
| Flujo de UI server-driven | `HttpCase` (tours) |
| Lógica de componentes / web client | **QUnit** (JS) |

## Tests de servidor (Python)
- Asserts reales sobre el resultado (no solo "no lanza excepción").
- Casos de borde, permisos (`with_user`) y multi-compañía.
- `setUpClass`/factories; sin `commit()`; `tagged('post_install', '-at_install')` cuando aplique.
- Tests de denegación de acceso (`AccessError`) cuando la spec lo pide.

## AAA y cobertura
- Sigue Arrange / Act / Assert.
- Cubre camino feliz, errores, bordes, permisos y multi-compañía.
- No persigas 100% de cobertura; prioriza lógica de negocio y seguridad.
- La cobertura se mide con `coverage.py` y el build falla por debajo del umbral.

## Tests de frontend (QUnit, Odoo 16) — NO HOOT
- `QUnit.module(...)` / `QUnit.test(...)`; `assert.*` para las aserciones.
- Helpers del web client en `addons/web/static/tests/helpers/` (p.ej. `utils.js`:
  `getFixture`, `mount`, `click`, `editInput`, `nextTick`; `mock_server.js`).
- Componentes OWL 2 se montan con los helpers de test del web client (no inventes firmas).
- **Fuente de verdad de la API**: copia patrones vigentes de `addons/web/static/tests/`
  y de los módulos EE.
- HOOT (`@odoo/hoot`) **no aplica en 16** (llegó en 18); no lo uses aquí.

## Upgrade-safety
- Cambios de esquema (campos/modelos) → script en `migrations/<version>/`.
- Datos `noupdate` no deben sobreescribirse.
- Campos eliminados → migración de datos.

## Ejecutar tests
`addons_path`/conexión salen del `config/<cliente>/dev.conf` y `odoo-bin` de la raíz
del entorno. **La BD destino NO está en el `dev.conf`**: la define el target en
`.vscode/launch.json` (`--db-filter`/`-d`); tómala de ahí. Patrón típico:
```bash
odoo-bin -c config/<cliente>/dev.conf -d <BD-del-target> -i <modulo> --test-enable --stop-after-init
# usa -u <modulo> si ya está instalado
```
Si falta la configuración o la BD, pídela; no inventes el comando.

## Cerrar el loop
- El gate completo es instalación + tests + cobertura.
- Si un artefacto de verificación se guarda, debe incluir comando, resultado y veredicto.
