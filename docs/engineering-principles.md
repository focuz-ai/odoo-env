# Principios de ingeniería — SOLID y Clean Code en clave Odoo (18.0 EE)

Principios de diseño OOP y código limpio **traducidos a los modismos de Odoo**. No son
genéricos: cada regla se enuncia como se aplica en un módulo Odoo EE, con su anti-patrón.
Esta es la **única fuente de verdad** de los principios; lo *mecánico* (mccabe, naming,
formato) lo ejecuta la capa de verificación (ver `conventions.md §Calidad y formato`), y lo
específico de ORM/seguridad vive en `orm-performance.md` y `security.md` (no se duplica aquí).

> Regla transversal: **el ORM de Odoo es Active Record**, no una arquitectura por capas.
> Los principios de abajo se aplican *dentro* de ese paradigma; ver §«Anti-patrones» antes
> de importar patrones de otros stacks (DDD, Repository, Service Layer).

## SOLID en Odoo

- **SRP — Single Responsibility.** Un modelo modela *una* entidad; un método hace *una*
  cosa. Extrae helpers privados (`_prepare_*`, `_compute_*`, `_get_*`) en vez de métodos
  kilométricos. La lógica de un asistente va en su `TransientModel`, no en el modelo de
  negocio. *Anti-patrón:* el «god model» que mezcla cálculo, validación, envío a un
  regulador y reporting en un solo método.

- **OCP — Open/Closed.** Extiende por **herencia de Odoo** (`_inherit` de modelo y de
  vista, herencia de QWeb) y por **hooks**, no modificando el core. Diseña tus propios
  métodos como puntos de extensión (`_prepare_invoice_vals`, hooks `provider` de EDI) para
  que otros módulos los sobreescriban sin forkear. *Anti-patrón:* copiar un método nativo
  entero para cambiar dos líneas (rompe ante cada upgrade).

- **LSP — Liskov.** Al sobreescribir un método heredado, respeta su **firma y su
  contrato** y llama a **`super()`** salvo que sustituyas el comportamiento a conciencia.
  Un `create`/`write` override debe seguir devolviendo lo que el llamador espera.
  *Anti-patrón:* un override que omite `super()` y rompe a los demás módulos que extienden
  el mismo método.

- **ISP — Interface Segregation.** Compón con **mixins pequeños y cohesivos**
  (`mail.thread`, `mail.activity.mixin`, `portal.mixin`) en vez de un mixin «todo en uno».
  Expón métodos específicos, no un único método con un `mode=` que hace de todo.

- **DIP — Dependency Inversion.** Depende de las **abstracciones de Odoo**, no de valores
  concretos hardcodeados: resuelve modelos por `self.env[name]`, config por
  `ir.config_parameter`/`res.config.settings`, rutas/credenciales por el `dev.conf`
  del cliente (nunca hardcodear). Para integraciones, extiende los hooks
  `provider` (ver `edi-integrations.md`), no acoples a un proveedor concreto.

## Clean Code en Odoo

- **Métodos pequeños y nombrados.** Complejidad mccabe ≤ 16 (la fuerza `ruff`). Privados
  con prefijo `_`. Nombre que diga *qué hace*, no *cómo*.
- **DRY.** Una sola representación de cada regla: un `@api.depends`/compute por campo; un
  helper reutilizable en vez de copiar lógica entre `create` y `write`; constraints en
  `@api.constrains`, no repetidas en cada llamada.
- **Early returns y poca anidación.** Sal temprano de los casos borde; evita pirámides de
  `if`. Filtra recordsets (`filtered`/`mapped`) en vez de bucles con `if` anidados.
- **Naming.** `snake_case` en Python; modelos `a.b.c`; campos e IDs XML descriptivos
  (ver `conventions.md §Naming`).
- **Lógica fuera de las vistas.** La lógica de negocio vive en los modelos, **nunca** en
  las vistas/XML (ver `conventions.md §Lógica y traducciones`).
- **Rule of three.** No abstraigas en la primera repetición; extrae el helper cuando haya
  un tercer uso real. La abstracción prematura cuesta más que la duplicación temprana.

## Disciplina agentic en Odoo

Los copilotos deben trabajar con el paradigma nativo de Odoo, pero con más trazabilidad:

- **Artefactos cerrados antes de implementar.** `proposal`, `specs`, `design` (si existe)
  y `tasks` deben dejar claro qué extender, qué crear, dónde tocar, cómo verificar y qué
  queda fuera. Una `Open Question` real bloquea `apply`; no se resuelve improvisando.
- **Una tarea verificable por vez, ejecución autónoma completa.** Implementa la siguiente
  tarea mínima de `tasks.md`, ejecuta el gate proporcional y marca el checkbox solo con
  evidencia. Si pasa, continúa con la siguiente tarea sin pedir permiso; detente solo ante
  bloqueo real.
- **Cuestiona inferencias antes de codear.** Verifica nombres de modelos/campos, hooks,
  mixins, APIs y módulos en el fuente de la serie 18.0 o en el mapa de reúso. Si algo no
  existe, actualiza el artefacto en vez de añadir una compatibilidad imaginaria.
- **Detecta patrones para reutilizar Odoo, no para sobre-abstraer.** Primero busca si CE/EE
  ya trae el mixin, hook o modelo; solo extrae helpers propios cuando la *rule of three* lo
  justifique. No introduzcas Repository/Service Layer artificial por comodidad del agente.

## Manejo de errores

- Usa la excepción **correcta** de `odoo.exceptions`: `UserError` (error de negocio
  esperado, cara al usuario), `ValidationError` (constraint), `AccessError` (permisos),
  `RedirectWarning` (cuando hay una acción correctiva). Mensajes envueltos en `_()`
  (traducibles), claros y accionables.
- **Nunca tragues excepciones** (`except Exception: pass`): o las manejas con contexto, o
  las propagas. Captura el tipo específico, no `Exception` genérico.
- En el commit/rollback de integraciones con reguladores, sé explícito con la idempotencia
  y la persistencia del estado (ver `edi-integrations.md`).

## Logging

- `_logger = logging.getLogger(__name__)` por módulo; **nunca `print`** (lo caza
  `pylint-odoo`). Nivel correcto: `debug`/`info`/`warning`/`error`.
- Incluye **contexto** en el mensaje (id del registro, módulo, operación):
  `_logger.info("EDI enviado", extra={"move_id": move.id})` o interpolando con `%s` (lazy,
  no f-strings en el log: lo exige `translation-not-lazy`/`logging-format`).

## Anti-patrones (no importar de otros stacks)

Odoo tiene su propio paradigma; estos patrones, válidos en Node/Java, son **ceremonia
inútil o frágil** aquí:

- **Repository / DAO sobre el ORM.** El recordset de Odoo *ya es* el repositorio
  (`search`, `browse`, `create`, `write`). Envolverlo en una clase `XRepository` añade
  indirección sin valor. Usa el ORM directamente.
- **Service Layer artificial.** La lógica va en métodos del modelo. Crea una clase/servicio
  aparte solo para lógica **transversal real** (y aún así, valora un `AbstractModel`/mixin
  o un helper en `tools`). No por defecto.
- **DDD formal (Aggregates, Value Objects).** Los modelos Odoo son Active Record, no
  agregados de un dominio rico. No fuerces *value objects* ni *aggregate roots*; modela con
  `models.Model`, relaciones y `@api.constrains`.
- **Inyección de dependencias estilo framework.** `self.env` ya es el contenedor. No montes
  un contenedor DI encima.
- **Sobre-abstracción / herencia profunda.** Prefiere composición (mixins) a jerarquías
  hondas; aplica la *rule of three*.

Y los anti-patrones Odoo de siempre (detallados en sus docs): `sudo()` indiscriminado y
fallos multi-compañía (`security.md`), N+1 y recomputes caros (`orm-performance.md`), SQL
crudo evitable, herencia de vistas frágil con `replace` (`conventions.md`).
