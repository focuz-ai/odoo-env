# Seguridad y permisos — Odoo 19.0 EE

## Reglas de acceso (ACL)
- **Todo modelo nuevo** necesita reglas en `ir.model.access.csv`.
- Permisos **mínimos por grupo**: no des `1,1,1,1` a todos por defecto.
- Separa lectura/escritura/creación/borrado según el rol real.
- Evita ACL para `base.group_public` y `base.group_portal` salvo que el caso de uso lo
  requiera explícitamente y tenga pruebas.

## Grupos y record rules
- Define grupos (`res.groups`) coherentes con los roles funcionales.
  XML ID `<modulo>_group_<nombre>`; record rules `<modelo>_rule_<grupo>`.
- En 19 los grupos cuelgan de un **`res.groups.privilege`** (contenedor de categoría):
  cada grupo enlaza `privilege_id` y forma escalera con `implied_ids`
  (user → manager → system; cf. `documents/security/security.xml`).
- Usa **record rules** donde el dato es sensible o multi-usuario (global vs por-grupo).
- Varias record rules del mismo grupo se **unen con OR** por operación: separa
  permisos explícitos por regla en vez de acumular dominios en una sola.
- Para permisos complejos, el patrón EE es **ACL amplia + record rule sobre un campo
  computado** de permiso: `[('user_permission', '!=', 'none')]` (documents),
  `[('user_has_access', '=', True)]` (knowledge).
- Revisa `perm_read/write/create/unlink` de cada regla.
- Las record rules globales deben ser simples y previsibles.

## Multi-compañía
- Campos `company_id` donde corresponda; `company_dependent=True` cuando el valor
  varía por compañía.
- Record rules de compañía (`company_ids`) para evitar fugas entre compañías; dominio
  estándar `('company_id', 'in', company_ids)`, con `+ [False]` cuando el registro es
  compartible entre compañías.
- En relaciones entre modelos con compañía, usa `check_company=True` cuando aplique.
- Los datos globales sin `company_id` deben estar justificados.

## sudo()
- Cada `sudo()` debe estar **justificado**. Prohibido usarlo para saltarse ACL por
  comodidad o exponer datos a usuarios sin permiso.
- El patrón real del fuente no es «sudo mínimo» sino sudo + **re-imposición del
  control** antes de devolver datos: la API unificada de 19 es
  `record.check_access('read')` / `check_access('write')` (sustituye a
  `check_access_rights`/`check_access_rule`, extintos en 19), o la verificación de
  token del documento.

## Controladores e inyección
- `@http.route`: `auth='public'` y `csrf=False` solo cuando esté justificado.
- Valida `request.params`; nunca confíes en la entrada del usuario.
- Sin `eval`/`safe_eval` sobre entrada de usuario; SQL siempre parametrizado
  (ver [orm-performance.md](orm-performance.md)).
- `sudo()` en controladores: nunca devuelvas datos obtenidos con sudo sin re-imponer
  el control (`check_access(...)` o token verificado — ver §sudo()).
- Tokens de acceso público SIEMPRE comparados en tiempo constante con
  `odoo.tools.consteq(esperado, recibido)` — nunca `==` (así lo hacen sign/documents/
  knowledge; planning no lo hace: no imitarlo).
- En 19 las rutas JSON son `type='jsonrpc'` (`type='json'` ya no existe). Las rutas
  `jsonrpc` públicas requieren autenticación funcional alternativa.

## Campos sensibles
- Contraseñas/tokens con `groups=` y/o `password=True`.
- PII no expuesta en vistas/portal sin control de acceso; restringe PII **a nivel de
  campo** con `groups=` (cf. `sign.log`: latitude/longitude/IP tras el grupo manager).
  `groups=fields.NO_ACCESS` bloquea el campo por completo.
- Credenciales en `res.company` o `ir.config_parameter` solo con acceso de administrador
  (`groups='base.group_system'`).

## Adjuntos y binarios

- `ir.attachment` hereda seguridad del `res_model/res_id`; enlaza al documento correcto.
- Evita adjuntos huérfanos accesibles por URL.

> Vulnerabilidades del entorno (CVEs de dependencias, versión de Python) se documentan
> en el `CLAUDE.md` del entorno, no aquí: este documento cubre el **código** del módulo.
