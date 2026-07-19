# ORM y rendimiento — Odoo 19.0 EE

## N+1 / consultas en bucles
- Nunca `search`/`read`/`browse` dentro de un `for`.
- Usa `_read_group`, `search_read`, `mapped`, `filtered`, o prefetch/agrupación.
- `_read_group` acepta specs de agregado: `['id:recordset']` (el más usado en el
  fuente), `'id:array_agg'`, `'<campo>:sum'`.
- `search_fetch(domain, ['campo', ...])` y `records.fetch([...])` precargan **solo**
  los campos necesarios en una consulta.
- Operaciones por lote: `create`/`write` en batch, no registro a registro.
- En Odoo 19, `create` recibe siempre una lista vía `@api.model_create_multi`.
- Si una override de `create` itera registro a registro, es un hallazgo.

## Computes
- `@api.depends` **completo y correcto**: declara todos los campos que el compute
  lee (si no, valores obsoletos).
- `store=True` solo con depends estables; cuida los recomputes masivos.
- `precompute=True` en computes `store=True` calculables al INSERT (evita el UPDATE
  posterior a la creación).
- Usa `@api.depends_context` cuando el resultado depende del contexto.

## Recordsets
- `ensure_one()` cuando el método asume un único registro.
- Evita `unlink` masivo sin control.

## Índices y búsqueda
- `index=True` en campos usados en filtros/búsquedas frecuentes y en `_order`.
- `index='btree_not_null'` para Many2one **nulables** (el estándar de facto del
  fuente); `index='trigram'` para campos buscados por nombre (`ilike`).
- Evita buscar por campos computados no almacenados.

## Medir rendimiento

- Las regresiones N+1 se prueban con `assertQueryCount`.
- Para depurar consultas puntuales: `--log-sql` o `odoo.tools.profiler`.

## Constraints
- `@api.constrains` para validación Python; preferir el constraint SQL
  (`models.Constraint`, ver [conventions.md](conventions.md)) cuando el caso lo
  permita (más eficiente y atómico).
- Evita queries pesadas dentro de un constrains.

## SQL crudo
- Solo si es imprescindible; la forma canónica es **`odoo.tools.SQL` componible**
  (auto-parametriza; `SQL.identifier(...)` para identificadores dinámicos,
  `SQL(", ").join(...)` para listas) — no strings a `cr.execute`.
- **Siempre** `flush_model()` antes de leer por SQL e `invalidate_recordset()` tras
  escribir por SQL: el ORM no ve lo que pasa por el cursor.
- El SQL crudo se salta ACL/record rules y multi-compañía: pasa `company_ids`
  explícito en el WHERE y valídalo a mano (ver [security.md](security.md)).

## Transacciones y savepoints
```python
# ❌ NUNCA commit manual
self.env.cr.commit()        # PROHIBIDO (lo gestiona el framework)

# ✅ Savepoints para aislar excepciones sin corromper la transacción principal
try:
    with self.env.cr.savepoint():
        do_risky_stuff()
except SpecificException:
    handle_error()
# ⚠️ Máximo ~64 savepoints por transacción (límite PostgreSQL)
```
Excepción — **crons batch** de larga duración: el commit intermedio va vía
`self.env['ir.cron']._commit_progress(processed, remaining=...)` (commitea, registra
avance y devuelve el tiempo restante para auto-throttling) + `_trigger()` para
re-encolar el cron si queda trabajo (cf. `sale_subscription`). El commit manual sigue
prohibido en flujos de request y en tests.

## Excepciones
```python
# ❌ Catch genérico
except Exception as e:
    logger.warning(e)

# ✅ Específicas
except ValidationError:
    ...
except UserError as e:
    raise UserError(_('Error: %s', e))
```
`except Exception` es legítimo SOLO para **aislamiento por-ítem** en fronteras de
integración (conectores/EDI): savepoint + rollback del ítem + log + continuar con el
resto del lote — el patrón real de los conectores del fuente.

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
