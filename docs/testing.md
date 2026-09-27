# Tests de addons Odoo EE — serie 17.0 (señal, fixtures y coste)

> Estándar completo de la serie 17.0 (modelo *self-contained*). §1–§9 son los principios
> de la plantilla global del sistema `odoo-openspec` (`docs/testing.md`), copiados tal
> cual para que esta página baste sola; §10 concreta la API de esta serie. Ante dudas de
> API, verifica en el fuente de la serie.

Tres ejes, con evidencia medida en Enterprise 19 (8.569 tests en 1.403 clases) y en
la auditoría de los tests que generó la fábrica (`l10n-pe`, 1.061 tests):
**qué probar** (señal), **cómo organizarlo** (fixtures) y **cuánto cuesta**
(tipos, tags y lectura del gate).

## 1. Trazabilidad escenario → test
- **Cada `#### Scenario` de las specs se prueba con un método de test**, cuyo docstring
  nombra el escenario. El reviewer empieza siempre por la tabla escenario → método
  (cubierto / hueco).
- **Escenario = método; clase = fixture** (§3): un escenario nunca justifica una clase
  ni un archivo propio. Un método cubre **varios** escenarios solo en dos formas
  (§2 «Granularidad»): tabla de casos con `subTest` o flujo encadenado; entonces su
  docstring los enumera (`"""Scenarios: A; B; C"""`) y la tabla sigue cerrando.
- «Tiene test» ≠ «está testeado»: el test debe ejercer comportamiento (§2) y la
  cobertura se mide (§7).

## 2. Qué probar: señal

### Integridad, no tautología
Forma canónica (patrón dominante en EE: 70–82 % de los tests de la muestra llama a una
acción de negocio antes de asertar):

> **arrange (fixture compartido) → ACCIÓN de negocio (`action_post`, `action_confirm`,
> `_create_invoices`, `reconcile`, un `_cron_*`, un cambio de estado…) → assert sobre
> los efectos DERIVADOS**: campo computado de OTRO registro, transición de estado,
> asiento/saldo generado, secuencia o golden-file.

- El esperado se **deriva** (a mano en el docstring, tras conversión o de otro
  registro), **nunca** es el literal pasado a `create()`.
- **Pocas llamadas assert, pero densas.** La mediana EE es 2 asserts por test; la
  densidad está en asertar tablas: `assertRecordValues` (1.565 usos) y
  `assertLinesValues` (609) verifican varios registros × campos de un flujo en una
  llamada. Tres o más efectos del mismo flujo → un `assertRecordValues`, no tres
  métodos. Varias entradas con la misma forma de test → una tabla con `subTest`.
- **La densidad es por-assert, no por-método**: se fusionan los asserts de un mismo
  flujo, pero se mantiene **un método por escenario de negocio**; fusionar escenarios
  distintos en un método tampoco es el patrón.
- `assertRecordValues` compara floats con los dígitos del campo y montos con el
  redondeo de la moneda: no redondees a mano; ordena el recordset
  (`.sorted("balance")`) cuando el orden no es el de creación.

### Granularidad: cuándo un método cubre varios escenarios
El coste está en la clase, no en el método: un método extra cuesta milisegundos
(savepoint, `flush_all` y limpieza de cachés en `TransactionCase.setUp`; en `l10n-pe`,
34 tests en 0,37 s con su cuerpo incluido) y una clase extra vuelve a pagar su fixture
(segundos). Por eso el default es **un método por escenario**: aísla el diagnóstico (el
primer assert que falla corta el método), no comparte estado entre escenarios (cada
método corre en su savepoint) y permite re-ejecutar uno con
`--test-tags /MÓDULO:Clase.test_metodo`. Hay tres agrupaciones legítimas:
1. **Tabla de casos con `subTest`**: la misma regla con distintos datos de entrada y
   resultado (tipo de cambio por tipo de movimiento; código HTTP → error). Un método
   recorre la tabla con `with self.subTest(**caso)`; Odoo reporta cada caso por separado
   y sigue tras un fallo. `subTest` no abre savepoint: si el caso escribe, usa registros
   propios del caso. Varios métodos idénticos salvo literales son una tabla.
2. **Flujo encadenado**: etapas de un mismo proceso (borrador → publicado → pagado →
   revertido; ventanas de `freeze_time` de una máquina de estados). Separarlas repetiría
   el arrange de las etapas previas en cada método; EE recorre las 6 ventanas del
   seguimiento de cobro en un método (`account_followup/tests/`).
3. **Tour**: cada `start_tour` arranca el navegador y carga el web client (segundos).
   Las comprobaciones de un mismo flujo de UI van en un tour, no una por tour — si un
   `Form` o un test JS unitario no las cubre antes (§4).

Nunca un método que mezcla escenarios independientes: no ahorra tiempo, oculta
regresiones tras el primer fallo y rompe la trazabilidad.

**Señales de test tautológico** — el `odoo-tests-reviewer` las marca como hallazgo y
propone fusionar/reescribir:
1. **Assert vacío o constante**: `assertTrue(True)`, o `assertTrue(record)` como único
   assert.
2. **Afirmar de vuelta el input**: el esperado es el literal pasado a `create()/write()`
   del mismo campo y registro.
3. **Sin acción de negocio** entre el `create` y el assert.
4. **Default del framework** (`state == 'draft'`, `active == True`) sin haberlo tocado.
5. **Fragmentación**: un test por campo sobre el mismo escenario en vez de un
   `assertRecordValues`.
6. **Smoke sin contraparte**: `assertTrue(record)` tras un `create` sin la variante
   negativa (`assertRaises(ValidationError, …)`) que pruebe la regla.

### Errores y permisos
- Aserta el **tipo concreto** de la excepción (`UserError`, `ValidationError`,
  `AccessError`). Usa `assertRaisesRegex` (o `with self.assertRaises(...) as cm` y el
  texto de `cm.exception`) cuando el tipo no distingue el caso, p.ej. varias ramas del
  addon lanzan el mismo `UserError`. El `msg=` de `assertRaises` no verifica nada: es el
  texto que se muestra si el assert falla.
- Permisos con un usuario real: `with_user`, `@users('login')`, `new_test_user`;
  denegación con `AccessError` y `mute_logger('odoo.addons.base.models.ir_rule')`.
  Multi-compañía con una segunda compañía del fixture (§3).
- Cubre camino feliz, errores, bordes (vacíos, cero/negativos, lotes de N registros) y
  permisos/multi-compañía **agrupados en los métodos del escenario**, no un test por
  categoría.

### Prohibido: tests sin señal
- **Tests estructurales en runtime**: leer fuentes `.py`/`.xml`, comparar el `arch` de
  una vista como texto, fijar la `version` literal del manifest, contar registros de
  datos o inspeccionar `_fields`/`_inherit`. No prueban comportamiento y se rompen con
  cada refactor. Lo estructural es de lint (`pylint-odoo`, pre-commit, check de
  manifest) o de `odoo-i18n`; una vista se prueba con `Form` o con el flujo que la usa.
- **Tests para cubrir líneas**: docstrings «(line N)» o archivos `*_extra.py` que
  recorren ramas sin escenario. La cobertura es un piso (§7): una línea de negocio sin
  cubrir es un **escenario que falta** (spec-first) o **código muerto**.
- **Mock de `requests`**: mockea la **función de transporte del addon** (el método que
  habla con el servicio) desde un `@contextmanager _mock_*` de la Common, con las
  respuestas en `tests/responses/`. EE parchea su transporte 398 veces y `requests` 22;
  en series recientes el framework bloquea la red real en los tests `standard`.
- **Ramas por demo**: un test o una Common que se comporta distinto si existe un
  registro demo no es determinista (local con demo, CI sin ella). Crea tus datos.

### Golden-file (payloads de regulador / EDI)
Escenarios que generan un documento para una autoridad (XML/JSON: CPE, CFDI,
FatturaPA, GRE…) se bloquean por **golden-file**, no campo a campo (estándar en
`docs/edi-integrations.md` §8):
- Documento de referencia en `tests/test_files/<caso>.xml`, leído con
  `file_open('<modulo>/tests/test_files/<caso>.xml', 'rb')`; en series recientes la
  Common de `account` trae además `assert_xml`/`assert_json`.
- Construido bajo `freeze_time` (sin fecha congelada cada corrida difiere).
- `assertXmlTreeEqual` compara atributos como diccionario y texto sin espacios, **pero
  respeta el orden de los nodos hijos**. Nodos que no puedes congelar (firma, hash,
  folio del servicio) → `___ignore___` en el golden.
- Transporte mockeado con respuestas fijas. Contra el servicio real, **clase gemela**
  (patrón EE, `delivery_ups/tests/test_delivery_ups.py`): la clase real con
  `('-standard', 'external')` y una subclase mock con `('standard', '-external')` que
  redeclara cada test llamando a `super()` bajo el mock (desde 18 el loader no ejecuta
  métodos heredados). En módulos `l10n_*`, `external_l10n` acompaña a `external`.
- Regenerar el golden es intencional: si el cambio del payload es deliberado,
  actualizas el archivo; si no, el test cazó una regresión.

## 3. Cómo organizarlo: fixtures

### Escenario = método, clase = fixture
`setUpClass` corre **una vez por clase, también en cada subclase que lo hereda**. Cada
clase extra sobre una Common costosa vuelve a pagar su fixture completo: Odoo 19 no
cachea el plan contable (cada clase carga el suyo). En `l10n-pe`, 93 clases pesadas
—una por escenario— hacían que el 72 % del tiempo de tests fuera `setUpClass`; EE usa
entre 1 y 6 clases por módulo y sus clases contables llevan 7,2 tests de media.
- **Una clase por fixture distinto** (otra compañía o plan contable, otro juego de
  usuarios, un `freeze_time` de clase, un patch de clase); dentro, **un método por
  escenario**.
- Compartir el fixture es seguro: el framework abre un cursor por clase y ejecuta cada
  test en un savepoint, limpiando cachés al terminar; ningún test ve lo que escribió
  otro. `cr.commit()` rompe ese aislamiento (desde 18 el framework lo prohíbe).
- Crea los datos en `setUpClass` (EE: 935 `setUpClass` frente a 146 `setUp`). `setUp`
  solo para parches por test (`self.patch`) o estado que el test destruye.

### Common del módulo, encadenada y compartida
- `tests/common.py` define la Common del módulo: fixtures en `setUpClass`, factories
  `_create_*` y mocks `@contextmanager _mock_*`. **Sin métodos `test_*`**: desde 18 el
  loader no ejecuta métodos heredados y en 16–17 se ejecutarían en cada subclase.
- **Hereda la Common del addon padre** en vez de montar compañía, plan contable o
  impuestos a mano: `BaseCommon` (ya desactiva tracking y correo en `cls.env`: no
  repitas `tracking_disable`), `AccountTestInvoicingCommon` (compañía, diarios,
  impuestos, `partner_a/b`, `product_a/b`, `setup_other_company`,
  `setup_other_currency`, y la factory de facturas de la serie), `AccountEdiTestCommon`
  con el país de la localización, `MailCommon`, `TestSubscriptionCommon`…
- **Compartida por import** entre los módulos del repo:
  `from odoo.addons.<modulo_base>.tests.common import <Modulo>Common`. Nunca copies una
  Common (en `l10n-pe` dos Commons compartían 146 de 166 líneas y divergían).
- Usuarios con `new_test_user(env, login, groups=...)` (o `mail_new_test_user`) en
  `setUpClass`. Varios registros de una vez con `create([...])` (ejercita además
  `@api.model_create_multi`).
- Tiempo con `freeze_time`: ventanas `with freeze_time(...)` para máquinas de estado; en
  18+ el `freeze_time` de `odoo.tests` como decorador de clase congela también los
  fixtures de `setUpClass`.
- **Sin dependencia de la demo**: EE tiene 7 referencias a registros demo entre 6.102
  `env.ref`. La carga de demo depende de la serie (19 no la instala por defecto) y del
  `dev.conf`; el test debe pasar igual con y sin ella.

```python
# tests/common.py: fixture compartido del módulo (sin métodos test_*)
from contextlib import contextmanager
from unittest.mock import patch

from odoo.tests.common import new_test_user

from odoo.addons.account.tests.common import AccountTestInvoicingCommon


class PagoCommon(AccountTestInvoicingCommon):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()  # compañía, plan, impuestos, partner_a/b, product_a/b
        cls.cobrador = new_test_user(cls.env, login="cobrador", groups="account.group_account_invoice")

    @contextmanager
    def _mock_pasarela(self, respuesta):
        with patch.object(type(self.env["pago.pasarela"]), "_enviar", return_value=respuesta) as mock:
            yield mock


# tests/test_pago.py: una clase por fixture, un método por escenario
from odoo.tests import tagged

from .common import PagoCommon


@tagged("post_install", "-at_install")
class TestPago(PagoCommon):
    def test_cobro_parcial_deja_residual(self):
        """Scenario: Cobro parcial deja residual."""
        factura = self.env["account.move"].create({...})  # vía la factory de la Common
        factura.action_post()
        with self._mock_pasarela({"estado": "ok"}):
            factura._cobrar_con_pasarela(60.0)  # acción de negocio del addon
        self.assertRecordValues(factura, [{"payment_state": "partial", "amount_residual": factura.amount_total - 60.0}])
```

## 4. Tipo de test y coste
Escalera de coste, de barato a caro; baja un peldaño solo si el escenario lo exige:

| Escenario | Test |
|-----------|------|
| Lógica de servidor (computes, constraints, estados, permisos) | `TransactionCase` |
| Onchanges/defaults tal como los dispara la vista (sin navegador) | `odoo.tests.Form(record, view=...)` |
| Controlador HTTP/JSON | `HttpCase` con `url_open` / `make_jsonrpc_request` (sin navegador) |
| Flujo de UI que `Form` no cubre | tour (`HttpCase.start_tour`) |
| Componente del web client | test unitario del framework JS de la serie (HOOT en 18+) |
| Regresión de N+1 en un flujo caliente | `assertQueryCount` + `@users` + `@warmup` |

- **Lo caro es el navegador, no la clase `HttpCase`.** EE tiene 2.606 tests HOOT frente
  a 612 tests con tour (≈4:1) y el 94 % de esos tests lanza un único tour: datos
  preparados en Python, un tour corto, asserts de BD al final. Un tour para comprobar un
  label o un `readonly` es un `Form`.
- `assertQueryCount` fija el número de queries de un flujo caliente (ver
  [orm-performance.md](orm-performance.md) §Medir el rendimiento). Estos tests son
  baratos y se quedan en `standard`: marcados `-standard` no corren nunca (en `l10n-pe`,
  5 de 7). Un tag propio sirve para seleccionarlos además, no para esconderlos.

## 5. Tags y selección
- Los tags por defecto son `standard` y `at_install`. **`at_install`** para lógica
  autocontenida del módulo. **`('post_install', '-at_install')`** cuando el test
  necesita el registry completo: contabilidad (541 de 544 clases EE sobre
  `AccountTestInvoicingCommon`), tours (142 de 142) u overrides de otros módulos.
- **Módulos `l10n_*`**: `('post_install_l10n', 'post_install', '-at_install')`, como
  exige el lint de Odoo (`test_lint/tests/test_l10n.py`). `post_install_l10n` es un tag
  de selección, **nunca para excluir tests de CI**: la CI del scaffolding selecciona por
  módulo (`/modulo`) y los ejecuta. Si la suite es lenta, reduce clases de fixture (§3);
  no la saques de CI (en `l10n-pe`, el 51 % de los tests quedó fuera así).
- Tests contra servicios reales: `('-standard', 'external')` (§2 Golden-file).
- Selectores `--test-tags` (`[-][tag][/módulo][:Clase][.método]`) para el loop interno:
  `odoo-harness test --module MÓDULO --tags /MÓDULO:Clase.test_metodo --json`, o
  `--tags /MÓDULO,-is_tour` para iterar sin tours. `--test-tags` implica
  `--test-enable`.
- El loader solo recoge los `tests/test_*.py` importados en `tests/__init__.py`: un
  archivo sin importar es un test que no existe (el gate bloquea si un módulo con
  archivos de test ejecuta 0 tests).

## 6. Cerrar el loop y leer el gate

### Desarrollo por tarea con gates Odoo
En Odoo la unidad verificable es el **escenario de spec ejecutado dentro de Odoo**:
primero el escenario, luego el test que lo prueba cuando ya existe superficie
ejecutable, después la implementación mínima y finalmente el gate.
- El agente implementa todas las tareas de `tasks.md` de forma autónoma; no delega la
  ejecución de tests ni pregunta si debe continuar entre tareas.
- Cada tarea tiene evidencia proporcional antes de marcarse `[x]`; si el módulo aún no
  es instalable, registra el gate parcial y no lo presentes como verificación completa.
- Para controladores definidos por la spec, el agente puede probar con `curl` y
  documentarlo; para flujos UI prioriza `Form`/`HttpCase`/tours y tests JS del
  framework vigente antes que Playwright ad hoc.

### Loop interno
Corre los tests con el harness: `odoo-harness test --module <modulo> --json` (por
defecto `--test-tags /<modulo>`: solo los tests del módulo, no los de sus
dependientes; `--tags` para un selector más fino, `--dry-run` para ver el comando).
Resuelve el `dev.conf` del cliente (`test_conf` de `openspec/config.yaml`), el
`odoo-bin` de `odools.toml` y la BD del target de `.vscode/launch.json`; lo que arma
equivale a `odoo-bin -c config/<cliente>/dev.conf -d <BD-del-target> -u <modulo>
--test-enable --test-tags /<modulo> --stop-after-init`. **La BD destino NO está en el
`dev.conf`**: sale del target. Si falta configuración o BD, pídela; no inventes el
comando. `result.summary` trae `tests`, `failed`, `errors`, `failures` (ids),
`log_errors`, `tests_by_module`, `test_time_s`, `setup_class_share` y
`slowest_classes`.

### Gate completo
**`/odoo-verify-build`** (`odoo-harness verify --change <id> --full`) instala (o
actualiza, si la BD base ya los trae) los módulos afectados y corre solo sus tests **en
una pasada** sobre una BD desechable (vacía, o duplicada de la BD base `test_template`
si el repo la declara), mide la cobertura de esos módulos y limpia la BD. Bloquea si hay
tests en rojo, líneas ERROR/CRITICAL en el log fuera de los tests (misma lista `ignore`
que `checklog-odoo.cfg`), 0 tests en un módulo con archivos de test, un log sin la línea
final de tests, un timeout de la pasada o cobertura bajo `fail_under` (sin `fail_under`
en la config, o sin Python medible en los módulos, la cobertura se informa sin gatear). Es precondición de
`/odoo-adversarial-review`. Los tests se apoyan en savepoints y en esa BD desechable:
nunca mutan la BD de desarrollo.

**Coste**: el resumen del gate trae `setup_class_share` (fracción del tiempo de tests
consumida por `setUpClass`) y `slowest_classes` (clases más caras, con su
`setUpClass`). Si `setUpClass` domina y varias clases heredan la misma Common costosa,
fusiónalas: unir las 4 clases de un módulo de `l10n-pe` en 1 bajó su tiempo un 31 % y
sus queries un 58 %. Es evidencia para el `odoo-tests-reviewer`, no un umbral.

### Reporte de verificación (trazabilidad de la ejecución)
Cada corrida de un gate se **persiste** en `openspec/changes/<id>/reports/`, escrita
por `odoo-harness` como par JSON + Markdown nombrado por el gate: `verify-full.md`
(gate completo), `task-<n>-gate.md` (gate de tarea) y `adversarial-review.md`
(revisión adversarial, vía `report write`). Incluye el comando, el resumen de tests,
la cobertura, la duración y el veredicto; cada escritura deja su evento en `metrics/`
con `duration_s`. Una tarea de test solo se marca como hecha cuando su reporte existe:
el agente **ejecuta** el gate, no lo delega (ver `AGENTS.md §Disciplina del flujo`).

## 7. Cobertura (piso, no objetivo)
- El gate mide la cobertura solo de los módulos afectados, con la config del repo
  (`pyproject.toml` del scaffolding o `.coveragerc`), y **falla bajo `fail_under`**.
  El umbral se sube con el tiempo; bajarlo es una decisión del repo, no del agente.
- No persigas el 100 % ni escribas tests para cubrir líneas (§2): prioriza ramas de
  negocio y de seguridad; los getters triviales se excluyen en `omit`/`exclude_also`.
- El `odoo-tests-reviewer` verifica que la cobertura se midió y cumple el umbral, y
  trata la lógica de negocio sin cubrir (computes, constraints, flujos de estado,
  ramas de permisos) como un escenario que falta o código muerto.

## 8. Tests de frontend (web client)
- Usa el **framework JS de la versión activa** y sus helpers (en series recientes HOOT:
  `@odoo/hoot`, `@odoo/hoot-dom`, `@odoo/hoot-mock`; en anteriores, QUnit). Nombres,
  bundles (`web.assets_unit_tests` / `web.assets_tests` en series con HOOT) y la forma
  de lanzarlos están en §10.
- **Test unitario antes que tour**: el componente se prueba montado con sus mock models
  (`static/tests/mock_server/mock_models/`) y `onRpc`; el tour queda para el flujo
  completo que ningún unitario cubre.
- La suite JS se ejecuta desde un test del módulo `web`: con `-u` del módulo no corre.
  Lánzala con `odoo-harness test --module <modulo> --no-update --tags <selector de la
  serie>` (selector en §10).
- **Fuente de verdad de la API**: copia patrones vigentes de `addons/web/static/tests/`
  y de los módulos EE; no inventes firmas. Un test nuevo en un framework obsoleto para
  la serie (p.ej. QUnit fuera de `static/tests/legacy/` con HOOT) es hallazgo.

## 9. Upgrade-safety
- Cambios de esquema (campos/modelos) → script en `migrations/<version>/`.
- Datos `noupdate` no deben sobreescribirse.
- Campos eliminados → migración de datos. Un `-i` en BD vacía no ejercita migraciones:
  cúbrelas con un test que cargue el script por ruta.

## 10. Concreción de la serie 17.0
- **Framework JS: QUnit** (HOOT llegó en 18; no lo uses aquí). `QUnit.module(...)` /
  `QUnit.test(...)` con `assert.*`; helpers del web client en
  `addons/web/static/tests/helpers/` (`utils.js`: `getFixture`, `mount`, `click`,
  `editInput`, `nextTick`; `mock_server.js`). Los componentes OWL 2 se montan con esos
  helpers; no inventes firmas.
- **Lanzar la suite JS**: `odoo-harness test --module <modulo> --no-update --tags
  "/web:WebSuite.test_js[<texto>]"`; `<texto>` filtra por nombre de `QUnit.module`.
- **Tours**: registro en `web_tour.tours`, pasos en el bundle `web.assets_tests`; se
  lanzan desde un `HttpCase` con `self.start_tour(url, "nombre_tour", login=...)`.
- **Demo**: las BD nuevas la cargan por defecto (salvo `without_demo` en el `dev.conf`);
  los tests no dependen de ella.
- **Tiempo**: `from freezegun import freeze_time` (17 no trae un `freeze_time` propio).
- **Loader**: ejecuta también los métodos `test_*` heredados, así que un test en la
  Common corre una vez por subclase.
- **Common de `account`**: `AccountTestInvoicingCommon.setUpClass(cls,
  chart_template_ref=None)`, `setup_company_data(...)`, `setup_multi_currency_data(...)`,
  `setup_other_currency(...)` e `init_invoice(...)`; golden con `assert_xml` o
  `assertXmlTreeEqual`.
- **Red**: el framework bloquea HTTP real en los tests `standard`.
- **Ejecutar**: `odoo-harness test --module <modulo> --json` (loop interno; equivale a
  `odoo-bin -c config/<cliente>/dev.conf -d <BD-del-target> -u <modulo> --test-enable
  --test-tags /<modulo> --stop-after-init`) y `odoo-harness verify --change <id> --full`
  (gate). La BD destino sale del target de `.vscode/launch.json`, no del `dev.conf`.
