# ORM y rendimiento — Odoo 18.0 EE

## N+1 / consultas en bucles
- Nunca `search`/`read`/`browse` dentro de un `for`.
- Usa `read_group`, `search_read`, `mapped`, `filtered`, o prefetch/agrupación.
- Operaciones por lote: `create`/`write` en batch, no registro a registro.

## Creación por lotes
- Sobrescribe `create` con **`@api.model_create_multi`** y recibe `vals_list` (lista de
  dicts), no `vals`. Es el contrato en Odoo 18: `create([{...}, {...}])` en una llamada.
- No iteres `super().create(vals)` registro a registro dentro del override.

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

## Medir el rendimiento (no adivinar)
- Las regresiones N+1 se *prueban*, no se opinan: en los flujos calientes (overrides de
  `create`/`write`, computes `store`, acciones masivas) añade un test con
  **`self.assertQueryCount(n)`** (o `with self.assertQueryCount(n):`) que fije el número
  de queries; un cambio que lo dispare rompe el test.
- Ese assert es el contraejemplo que pide el `odoo-orm-perf-reviewer`: un hallazgo de
  «será lento» se confirma o descarta con un query-count real.
- Para depurar consultas puntualmente: `odoo-bin … --log-sql` o `odoo.tools.profiler`.

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
