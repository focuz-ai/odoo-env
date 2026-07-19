# ORM y rendimiento — Odoo 17.0 EE

## N+1 / consultas en bucles
- Nunca `search`/`read`/`browse` dentro de un `for`.
- Usa `_read_group`/`search_read`, `mapped`, `filtered`, o prefetch/agrupación.
- Agregación: la firma **moderna** de `_read_group(domain, groupby, aggregates)` con
  specs de agregado — `['id:recordset']` devuelve recordsets por grupo (patrón del
  fuente 17, p.ej. `account`), `['amount:sum', 'id:count']` para sumas/conteos.
  Evita post-procesar en Python lo que un spec de agregado ya resuelve.
- Operaciones por lote: `create`/`write` en batch, no registro a registro.
- En Odoo 17, `create` recibe siempre una lista vía `@api.model_create_multi`.

## Computes
- `@api.depends` **completo y correcto**: declara todos los campos que el compute
  lee (si no, valores obsoletos).
- `store=True` solo con depends estables; cuida los recomputes masivos.
- `precompute=True` en computados almacenados calculables en el `create` (depends
  solo de campos del propio registro): evita el UPDATE posterior al INSERT.
- Usa `@api.depends_context` cuando el resultado depende del contexto.

## Recordsets
- `ensure_one()` cuando el método asume un único registro.
- Evita `unlink` masivo sin control.

## Índices y búsqueda
- `index=True` (btree) en campos usados en filtros/búsquedas frecuentes y en `_order`.
- Elige el tipo de índice: `index='btree_not_null'` para campos mayormente NULL que
  se filtran por «tiene valor» (el patrón dominante del fuente 17 en Many2one
  opcionales); `index='trigram'` para campos Char buscados con `ilike`.
- Evita buscar por campos computados no almacenados.

## Constraints
- `@api.constrains` para validación Python; preferir `_sql_constraints` cuando el
  caso lo permita (más eficiente y atómico). En 17 `_sql_constraints` (lista de
  tuplas en el modelo) es la forma vigente.
- Evita queries pesadas dentro de un constrains.

## SQL crudo
- `self.env.cr.execute` solo si es imprescindible.
- Forma canónica en 17: **`odoo.tools.SQL`** componible —
  `self.env.cr.execute(SQL("... WHERE id = %s", record.id))`; los fragmentos se
  componen anidando objetos `SQL` (identificadores con `SQL.identifier`), nunca
  concatenando strings.
- **Siempre parametrizado** (nunca f-strings con entrada del usuario).
- Coherencia con el ORM: `flush_model()` de los modelos leídos **antes** de la
  query (el SQL no ve lo pendiente en caché) e `invalidate_model()`/
  `invalidate_recordset()` **después** de un UPDATE/DELETE crudo.
- El SQL crudo se salta ACL/record rules y multi-compañía: valídalo a mano (ver
  [security.md](security.md)).

## Transacciones y savepoints
```python
# ❌ Commit manual en requests HTTP y en tests
self.env.cr.commit()        # PROHIBIDO ahí (lo gestiona el framework)

# ✅ Savepoints para aislar excepciones sin corromper la transacción principal
try:
    with self.env.cr.savepoint():
        do_risky_stuff()
except SpecificException:
    handle_error()
# ⚠️ Máximo ~64 savepoints por transacción (límite PostgreSQL)
```
Excepción acotada: en **crons batch** que procesan volúmenes grandes, el commit
manual **por lote** es el patrón del fuente (persistir progreso y liberar locks
entre lotes). Solo en el método del cron, nunca en flujos request/tests.

## Excepciones
```python
# ❌ Catch genérico que silencia errores
except Exception as e:
    logger.warning(e)

# ✅ Específicas
except ValidationError:
    ...
except UserError as e:
    raise UserError(_('Error: %s', e))
```
Excepción acotada: `except Exception` se admite solo como **aislamiento por-ítem**
en integraciones/batch (un registro que falla no tumba el lote): dentro de un
`savepoint()`, registrando el error en el registro/log y continuando. Nunca como
catch global silencioso.

## onchange vs compute
- `onchange` es solo UI. La lógica que debe garantizarse también vía API/import va en
  compute/constraint, no en onchange.

## Buenas prácticas Python (rendimiento/idiom)
```python
my_dict = {'foo': 3, 'bar': 4}      # literales
new_dict = dict(my_dict)            # copiar (no .clone())
if collection:                      # colección como booleano (no len())
records.with_context(**extra).do_stuff()   # merge de contexto
```
