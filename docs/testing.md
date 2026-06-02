# Tests, trazabilidad y upgrade-safety — Odoo 18.0 EE

## Trazabilidad escenario → test
- **Cada `#### Scenario` de las specs debe tener un test** que lo ejercite.
- El reviewer empieza siempre por la tabla escenario → test (cubierto / hueco).

## Tipo de test correcto
| Escenario | Test |
|-----------|------|
| Lógica de servidor (modelos, computes, constraints, permisos, estados) | `TransactionCase` |
| Flujo de UI server-driven | `HttpCase` (tours) |
| Lógica de componentes / web client | **HOOT** (JS) |

## Tests de servidor (Python)
- Asserts reales sobre el resultado (no solo "no lanza excepción").
- Casos de borde, permisos (`with_user`) y multi-compañía.
- `setUpClass`/factories; sin `commit()`; `tagged('post_install', '-at_install')` cuando aplique.
- Tests de denegación de acceso (`AccessError`) cuando la spec lo pide.

## Tests de frontend (HOOT, Odoo 18) — NO QUnit
- `@odoo/hoot` → `describe`, `test`, `expect`, `beforeEach`.
- `@odoo/hoot-dom` → interacción/consulta DOM (`click`, `queryOne`, `queryAll`...).
- `@odoo/hoot-mock` → tiempo/red (`advanceTime`, mocks).
- Helpers del web client: `@web/../tests/web_test_helpers` (`mountWithCleanup`,
  `defineModels`, `makeMockServer`...).
- **Fuente de verdad de la API**: copia patrones vigentes de `addons/web/static/tests/`
  y de los módulos EE; no inventes firmas.
- Todo test JS nuevo en QUnit fuera de `static/tests/legacy/` es framework **obsoleto**
  → marcar como hallazgo.

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
