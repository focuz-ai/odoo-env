# Seguridad y permisos — Odoo 17.0 EE

## Reglas de acceso (ACL)
- **Todo modelo nuevo** necesita reglas en `ir.model.access.csv`.
- Permisos **mínimos por grupo**: no des `1,1,1,1` a todos por defecto.
- Separa lectura/escritura/creación/borrado según el rol real.

## Grupos y record rules
- Define grupos (`res.groups`) coherentes con los roles funcionales.
  XML ID `<modulo>_group_<nombre>`; record rules `<modelo>_rule_<grupo>`.
- Usa **record rules** donde el dato es sensible o multi-usuario (global vs por-grupo).
- Revisa `perm_read/write/create/unlink` de cada regla.

## Multi-compañía
- Campos `company_id` donde corresponda; `company_dependent=True` cuando el valor
  varía por compañía.
- Record rules de compañía (`company_ids`) para evitar fugas entre compañías.

## sudo()
- Cada `sudo()` debe estar **justificado**. Prohibido usarlo para saltarse ACL por
  comodidad o exponer datos a usuarios sin permiso.

## Controladores e inyección
- `@http.route`: `auth='public'` y `csrf=False` solo cuando esté justificado.
- Valida `request.params`; nunca confíes en la entrada del usuario.
- Sin `eval`/`safe_eval` sobre entrada de usuario; SQL siempre parametrizado
  (ver [orm-performance.md](orm-performance.md)).

## Campos sensibles
- Contraseñas/tokens con `groups=` y/o `password=True`.
- PII no expuesta en vistas/portal sin control de acceso.

> Vulnerabilidades del entorno (CVEs de dependencias, versión de Python) se documentan
> en el `CLAUDE.md` del entorno, no aquí: este documento cubre el **código** del módulo.
