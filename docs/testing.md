# Tests, trazabilidad y upgrade-safety — Odoo 18.0 EE

## Trazabilidad escenario → test
- **Cada `#### Scenario` de las specs debe tener un test** que lo ejercite.
- El reviewer empieza siempre por la tabla escenario → test (cubierto / hueco).

## Desarrollo por tarea con gates Odoo
El flujo no aplica TDD unitario aislado del framework. En Odoo, la unidad verificable es
el **escenario de spec ejecutado dentro de Odoo**: primero se redacta el escenario, luego
el test Odoo que lo prueba cuando ya existe una superficie ejecutable, después la
implementación mínima y finalmente el gate.

- El agente implementa de forma autónoma todas las tareas de `tasks.md`; no delega al
  usuario la ejecución de tests ni pregunta si debe continuar entre tareas.
- Cada tarea debe tener evidencia proporcional antes de marcarse `[x]`: lint/checks sobre
  archivos tocados y, cuando el módulo ya es instalable, instalación/test focalizado.
- Si una tarea todavía no deja el módulo instalable (p.ej. solo añade parte del modelo y
  falta seguridad/manifest), registra el gate parcial y no lo presentes como verificación
  completa. El full `/odoo-verify-build` sigue siendo obligatorio antes de la revisión
  adversarial.
- Usa `--test-tags=/modulo` o tags específicos para acelerar tests focalizados; en Odoo
  `--test-tags` implica `--test-enable`. Mantén tags nativos (`standard`, `at_install`,
  `post_install`) y añade tags propios solo si ayudan a seleccionar escenarios.
- Para controladores HTTP/JSON definidos por la spec, el agente puede ejecutar pruebas
  manuales con `curl` y documentarlas. Para flujos UI de Odoo, prioriza `HttpCase`/tours
  y tests HOOT antes que Playwright ad hoc.
- Los tests Odoo deben apoyarse en transacciones/savepoints y BD desechable del gate; no
  mutar la BD de desarrollo ni depender de limpieza manual del usuario.

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

## Estructura de un test: un escenario de negocio, agrupado (no fragmentado)
- **Un test = un ESCENARIO de negocio**, no un campo ni una categoría. El patrón es
  *Arrange* (fixture compartido) → **Acción de negocio** → *Assert sobre los efectos
  derivados*. Un método puede encadenar varias acciones del mismo flujo (p.ej. varias
  ventanas de `freeze_time`) y agrupar 3-15 asserts relacionados; nombre que diga qué
  verifica (`test_<qué>_<condición>`).
- **Agrupa, no multipliques.** Verifica varios efectos de un mismo flujo en un método con
  `assertRecordValues`/`assertLinesValues` en vez de un test por campo. Un test por campo
  sobre el mismo escenario es fragmentación sin valor: **menos tests, más densos, es el
  objetivo** (patrón dominante en Enterprise, ver §Test de integridad).
- **Categorías que un escenario no trivial no puede ignorar** (no basta el camino feliz).
  Cúbrelas **agrupándolas** en los tests del escenario, no creando un test por categoría:
  1. **Camino feliz** — entrada válida → resultado esperado.
  2. **Errores** — entrada inválida → la excepción correcta (`UserError`/`ValidationError`)
     y su mensaje.
  3. **Bordes** — límites, vacíos, cero/negativos, **lotes** (recordsets de N, no solo 1).
  4. **Permisos / multi-compañía** — `with_user`, denegación (`AccessError`), aislamiento
     por compañía.
  5. **Integración** — interacción con otros módulos/servicios (mockea el **transporte**,
     no el ORM).
- El `odoo-tests-reviewer` exige que los escenarios no triviales cubran estos ejes, no solo
  que «exista un test».

## Test de integridad vs. test tautológico
Un test tautológico re-afirma lo que el código acaba de asignar, o solo comprueba «no
lanza excepción». No prueba comportamiento: pasa siempre por construcción. La forma
canónica de un test de **integridad** (patrón dominante en Enterprise) es:

> **arrange (fixture compartido) → ACCIÓN de negocio (`action_post`, `action_confirm`,
> `_create_invoices`, `reconcile`, un `_cron_*`, un cambio de estado…) → assert sobre los
> efectos DERIVADOS**: campo computado de OTRO registro, transición de estado, asiento/
> saldo contable generado, secuencia, o golden-file.

El valor esperado se **deriva** (a mano en el docstring, tras conversión, o de otro
registro), **nunca** es el literal que se pasó a `create()`. Entre el `create` y el
assert **siempre** hay una acción de negocio. Refs reales:
`assertRecordValues(batch, [{'amount_residual': 200, ...}])` tras `create_batch_payment()`
en `account_batch_payment/tests/`; la máquina de estados completa del followup en **un**
método con 6 ventanas de `freeze_time` en `account_followup/tests/`.

**Señales de test tautológico** — el `odoo-tests-reviewer` las marca como hallazgo y
propone **fusionar/reescribir**, no solo constatar que «existe un test»:
1. **Assert vacío o constante**: `assertTrue(True)`, `assertFalse(None)`, o `assertTrue(record)`
   aislado como único assert (placeholder muerto — bórralo).
2. **Afirmar de vuelta el input**: el valor esperado es idéntico al literal pasado a
   `create()/write()` del mismo campo y registro. Válido SOLO si el esperado es un campo
   **computado de otro registro** o el resultado de una conversión.
3. **Sin acción de negocio**: no hay ninguna llamada a un método entre el `create` y el
   assert (cuerpo = `create` + `assertEqual`).
4. **Default del framework**: assert sobre un valor que el framework ya pone (`state ==
   'draft'`, `active == True`, `sequence == 10`) sin haberlo tocado.
5. **Fragmentación**: un test por campo sobre el mismo escenario en vez de un
   `assertRecordValues`/`assertLinesValues` agrupado.
6. **Smoke sin contraparte**: `assertTrue(record)` tras un `create` como única verificación,
   sin su variante negativa (`assertRaises(ValidationError, …)`) que pruebe la regla.

## Tests golden-file (payloads de regulador / EDI)
Escenarios que generan un artefacto serializado para una autoridad fiscal (XML/JSON:
CPE, CFDI, FatturaPA, GRE/e-waybill…) se bloquean por **golden-file** en vez de
asserts campo a campo. Ver [edi-integrations.md](edi-integrations.md) §8. Patrón:
- Guarda el documento de referencia correcto en `tests/test_files/<caso>.xml`.
- Constrúyelo bajo `freeze_time(cls.frozen_today)` (sin congelar la fecha, cada corrida
  difiere y el test nunca pasa dos veces).
- Compara con `assertXmlTreeEqual` (compara el árbol, no el texto: ignora orden de
  atributos/whitespace). Nodos volátiles que no puedes congelar (firma, hash, folio que
  devuelve el servicio) → marca `___ignore___` en el golden file y el comparador los salta.
- Mockea la **función de transporte** (no `requests` directo) con respuestas fijas en
  `tests/responses/`. Tags: `@tagged('post_install_l10n','post_install','-at_install')`;
  el test contra el servicio real va en `*_external.py` con `('external','-standard')`.
- Regenerar el golden es intencional: si el cambio del payload es deliberado, actualizas
  el archivo; si no, el test cazó una regresión en lo que envías al regulador.

```python
from freezegun import freeze_time
from odoo.tests import tagged
from odoo.addons.account.tests.common import AccountTestInvoicingCommon


@tagged("post_install_l10n", "post_install", "-at_install")
class TestEdiXml(AccountTestInvoicingCommon):
    frozen_today = "2026-06-15"

    def _assert_edi_xml(self, move, golden):
        """Compara el payload generado contra tests/test_files/<golden>.xml."""
        with freeze_time(self.frozen_today):
            generated = self.env["account.edi.xml.ubl_pe"]._export_invoice(move)[0]
        # el golden marca nodos volátiles (firma, hash, fecha) con ___ignore___
        expected = self._read_test_file(f"{golden}.xml")
        self.assertXmlTreeEqual(
            self.get_xml_tree_from_string(generated),
            self.get_xml_tree_from_string(expected),
        )
```
Ref: `l10n_co_dian/tests/common.py`, `l10n_pe_edi/tests/test_edi_xmls.py`.

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

## Cerrar el loop (ejecutar tests)
Usa el `dev.conf` del cliente (de `openspec/config.yaml` `test_conf`) como `-c`;
`odoo_bin` sale de `odools.toml`. **La BD destino NO está en el `dev.conf`**: la define
el target correspondiente en `.vscode/launch.json` (`--db-filter`/`-d`); tómala de ahí.
Patrón típico:
```bash
odoo-bin -c config/<cliente>/dev.conf -d <BD-del-target> -i <modulo> --test-enable --stop-after-init
# usa -u <modulo> si ya está instalado
```
Si falta la configuración o la BD, pídela; no inventes el comando.

El gate determinista del flujo es **`/odoo-verify-build`**: corre lint + instalación +
tests + cobertura contra una BD desechable y devuelve un veredicto. Es precondición de
`/odoo-adversarial-review` (no se revisa lo que no instala ni pasa tests).

### Reporte de verificación (trazabilidad de la ejecución)
El resultado de cada corrida de un gate se **persiste** como artefacto del change en
`openspec/changes/<id>/reports/`, con nombre datado `YYYY-MM-DD-<gate>.md` (p.ej.
`2026-06-28-verify-build.md`, `2026-06-28-adversarial-review.md`). Incluye: el comando
ejecutado, el resumen de resultados (lint, tests passed/failed/skipped, cobertura %) y el
veredicto. Así la ejecución queda **trazable**, no efímera, y `/opsx:archive` puede
confirmar que el cambio se verificó. Una tarea de test solo se marca como hecha cuando su
reporte existe — el agente **ejecuta** el gate, no lo delega.

## Cobertura (no solo «existe un test»)
- «Tiene un test» ≠ «está testeado». Mide cobertura con `coverage.py`
  (`coverage run --source=<modulo> odoo-bin … --test-enable`; luego `coverage report`).
- Umbral por repo en `pyproject.toml` (`[tool.coverage.report] fail_under`); súbelo con
  el tiempo. Por debajo del umbral, el build **falla**.
- El `odoo-tests-reviewer` verifica: (1) cada escenario tiene test (trazabilidad), y
  (2) que la cobertura se mide y cumple el umbral; señala líneas de lógica de negocio
  (computes, constraints, flujos de estado, ramas de permisos) sin cubrir.
- No persigas el 100%: prioriza ramas de negocio y de seguridad sobre getters triviales
  (excluidos en `omit`/`exclude_also` del `pyproject.toml`).
