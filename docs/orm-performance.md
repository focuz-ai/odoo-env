# ORM y rendimiento — Odoo 16.0 EE

## N+1 / consultas en bucles
- Nunca `search`/`read`/`browse` dentro de un `for`.
- Usa `read_group`, `search_read`, `mapped`, `filtered`, o prefetch/agrupación.
- Operaciones por lote: `create`/`write` en batch, no registro a registro.
- En Odoo 16, `create` recibe siempre una lista vía `@api.model_create_multi`.
- Si una override de `create` itera registro a registro, es un hallazgo.

## Computes
- `@api.depends` **completo y correcto**: declara todos los campos que el compute
  lee (si no, valores obsoletos).
- `store=True` solo con depends estables; cuida los recomputes masivos.
- Usa `@api.depends_context` cuando el resultado depende del contexto.

## Recordsets
- `ensure_one()` cuando el método asume un único registro.
- Evita `unlink` masivo sin control.

## Índices y búsqueda
- `index=True` en campos usados en filtros/búsquedas frecuentes y en `_order`.
- Evita buscar por campos computados no almacenados.

## Medir rendimiento
- Las regresiones N+1 se prueban con `assertQueryCount` (`odoo.tests.common.TransactionCase`).
- Para depurar consultas puntuales: `--log-sql` o `odoo.tools.profiler` (`odoo/tools/profiler.py`,
  disponible en el fuente de 16.0).

## Constraints
- `@api.constrains` para validación Python; preferir `_sql_constraints` cuando el
  caso lo permita (más eficiente y atómico).
- Evita queries pesadas dentro de un constrains.

## SQL crudo
- `self.env.cr.execute` solo si es imprescindible.
- **Siempre parametrizado** (nunca f-strings con entrada del usuario).
- El SQL crudo se salta ACL/record rules y multi-compañía: valídalo a mano (ver
  [security.md](security.md)).

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
