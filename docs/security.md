# Seguridad y permisos — Odoo 17.0 EE

## Reglas de acceso (ACL)
- **Todo modelo nuevo** necesita reglas en `ir.model.access.csv`.
- Permisos **mínimos por grupo**: no des `1,1,1,1` a todos por defecto.
- Separa lectura/escritura/creación/borrado según el rol real.
- Cuando el acceso depende del **dato** y no del rol, el patrón del fuente es
  **ACL amplia + record rule** que restringe por registro (incluso sobre un campo
  computado almacenado que encapsula la condición) — no multipliques grupos.

## Grupos y record rules
- Define grupos (`res.groups`) coherentes con los roles funcionales.
  XML ID `<modulo>_group_<nombre>`; record rules `<modelo>_rule_<grupo>`.
- Usa **record rules** donde el dato es sensible o multi-usuario (global vs por-grupo).
- Revisa `perm_read/write/create/unlink` de cada regla.

## Chequeo programático de acceso (API de la serie 17)
- `check_access_rights(operation)` (ACL del modelo) + `check_access_rule(operation)`
  (record rules sobre el recordset). Llama **ambos** antes de operar con datos
  obtenidos fuera del flujo ORM normal (SQL crudo, `sudo()`).
- No existe en 17 una `check_access()` unificada (llegó después); no la uses aquí.

## Multi-compañía
- Campos `company_id` donde corresponda; `company_dependent=True` cuando el valor
  varía por compañía.
- Record rule de compañía con el patrón del fuente:
  `[('company_id', 'in', company_ids)]`; si el modelo admite registros
  compartidos (sin compañía), `[('company_id', 'in', company_ids + [False])]`.

## sudo()
- Cada `sudo()` debe estar **justificado**. Prohibido usarlo para saltarse ACL por
  comodidad o exponer datos a usuarios sin permiso.
- Patrón del fuente cuando hace falta elevar: **sudo amplio + re-chequeo** — opera
  con `sudo()` pero valida antes el acceso del usuario real
  (`record.check_access_rights(...)` + `check_access_rule(...)`, o filtrando por
  lo que el usuario puede ver) para no ampliar el alcance de datos.

## Controladores e inyección
- `@http.route`: `auth='public'` y `csrf=False` solo cuando esté justificado.
- Rutas JSON con `type='json'` (la forma de la serie 17); `type='http'` para el resto.
- Tokens de acceso público (portal, URLs firmadas): compara **siempre** con
  `odoo.tools.consteq(token_recibido, token_esperado)` — nunca `==` (timing attack).
- Valida `request.params`; nunca confíes en la entrada del usuario.
- Sin `eval`/`safe_eval` sobre entrada de usuario; SQL siempre parametrizado
  (ver [orm-performance.md](orm-performance.md)).

## Campos sensibles
- Contraseñas/tokens con `groups=` y/o `password=True`.
- PII: restringe el **campo** con `groups='base.group_system'` (u otro grupo
  fino) en la definición Python — el campo desaparece de vistas y RPC para el
  resto; no confíes solo en ocultarlo en la vista.
- PII no expuesta en vistas/portal sin control de acceso.

> Vulnerabilidades del entorno (CVEs de dependencias, versión de Python) se documentan
> en el `CLAUDE.md` del entorno, no aquí: este documento cubre el **código** del módulo.
