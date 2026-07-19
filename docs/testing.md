# Tests, trazabilidad y upgrade-safety — Odoo 19.0 EE

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
| Lógica de componentes / web client | **HOOT** (JS) |

## Tests de servidor (Python)
- Asserts reales sobre el resultado (no solo "no lanza excepción").
- Casos de borde, permisos (`with_user`) y multi-compañía.
- `setUpClass`/factories; sin `commit()`; `tagged('post_install', '-at_install')` cuando aplique.
- Hereda de la clase `*Common` del addon padre en vez de duplicar fixtures fiscales:
  `AccountTestInvoicingCommon`, `AccountEdiTestCommon` con
  `@AccountEdiTestCommon.setup_country('pe')` (cf. `l10n_pe_edi/tests/common.py`).
- `odoo.tests.Form` para ejercitar onchanges/defaults como lo haría el cliente web,
  sin navegador.
- Tests de denegación de acceso (`AccessError`) cuando la spec lo pide.
- Regresiones de rendimiento y de N+1 (incl. en ACL): `assertQueryCount` con los
  decoradores `@users` y `@warmup` (cf. `documents/tests/test_documents_access.py`).
- Densidad: fusiona los asserts de un mismo flujo
  (`assertRecordValues(records, [{...}, ...])`) manteniendo **un método por escenario
  de negocio**; no fusiones métodos de escenarios distintos.

## AAA y cobertura

- Sigue Arrange / Act / Assert.
- Cubre camino feliz, errores, bordes, permisos y multi-compañía.
- No persigas 100% de cobertura; prioriza lógica de negocio y seguridad.
- La cobertura se mide con `coverage.py` y el build falla por debajo del umbral.

## Tests de frontend (HOOT, Odoo 19) — NO QUnit
- Ficheros `static/tests/*.test.js`, en el bundle `web.assets_unit_tests`.
- `@odoo/hoot` → `describe`, `test`, `expect`, `beforeEach`.
- `@odoo/hoot-dom` → interacción/consulta DOM (`click`, `queryOne`, `queryAll`...).
- `@odoo/hoot-mock` → tiempo/red (`advanceTime`, mocks).
- Helpers del web client: `@web/../tests/web_test_helpers` (`defineModels`,
  `defineMailModels`, `onRpc`, `mountView`, `mountWithCleanup`, `patchWithCleanup`,
  `contains`, `makeMockServer`...). Los mock models reutilizables viven en
  `static/tests/mock_server/mock_models/*.js`.
- **Fuente de verdad de la API**: copia patrones vigentes de `addons/web/static/tests/`
  y de los módulos EE; no inventes firmas.
- Todo test JS nuevo en QUnit fuera de `static/tests/legacy/` es framework **obsoleto**
  → marcar como hallazgo.

## Tours
- Registro en `registry.category("web_tour.tours")` con `steps: () => [...]`
  (**arrow perezosa**, no array literal); van al bundle `web.assets_tests`.
- Se lanzan desde un `HttpCase` con `start_tour(url, nombre)`.

## Upgrade-safety
- Cambios de esquema (campos/modelos) → script en `migrations/<version>/` (versión
  corta del manifest; ver [version-migration.md](version-migration.md)).
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
