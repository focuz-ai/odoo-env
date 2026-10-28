# Seguridad y permisos — Odoo 16.0 EE

## Reglas de acceso (ACL)
- **Todo modelo nuevo** necesita reglas en `ir.model.access.csv`.
- Permisos **mínimos por grupo**: no des `1,1,1,1` a todos por defecto.
- Separa lectura/escritura/creación/borrado según el rol real.
- Evita ACL para `base.group_public` y `base.group_portal` salvo que el caso de uso lo
  requiera explícitamente y tenga pruebas.

## Grupos y record rules
- Define grupos (`res.groups`) coherentes con los roles funcionales.
  XML ID `<modulo>_group_<nombre>`; record rules `<modelo>_rule_<grupo>`.
- Usa **record rules** donde el dato es sensible o multi-usuario (global vs por-grupo).
- Patrón core: **ACL amplia + record rule** que recorta por registro; no modeles
  permisos por-registro solo con ACL. Si el permiso es complejo, compútalo a un
  **campo** (p.ej. `knowledge.article.user_permission` en 16 EE) y apóyate en él en
  reglas y vistas.
- Revisa `perm_read/write/create/unlink` de cada regla.
- Las record rules globales deben ser simples y previsibles.

## Multi-compañía
- Campos `company_id` donde corresponda; `company_dependent=True` cuando el valor
  varía por compañía.
- Record rules de compañía (`company_ids`) para evitar fugas entre compañías.
- En dominios manuales, el patrón es `('company_id', 'in', company_ids)`; si el modelo
  admite registros compartidos, añade `+ [False]` explícito.
- En relaciones entre modelos con compañía, usa `check_company=True` cuando aplique.
- Los datos globales sin `company_id` deben estar justificados.

## sudo()
- Cada `sudo()` debe estar **justificado**. Prohibido usarlo para saltarse ACL por
  comodidad o exponer datos a usuarios sin permiso.
- Patrón seguro cuando el sudo es amplio: opera con `sudo()` pero **re-chequea** el
  permiso real del usuario con `check_access_rights()` + `check_access_rule()` antes
  de devolver o escribir (en 16 son dos llamadas separadas; no existe un
  `check_access()` unificado — eso es de series posteriores).

## Controladores e inyección
- `@http.route`: `auth='public'` y `csrf=False` solo cuando esté justificado.
- Valida `request.params`; nunca confíes en la entrada del usuario.
- Sin `eval`/`safe_eval` sobre entrada de usuario; SQL siempre parametrizado
  (ver [orm-performance.md](orm-performance.md)).
- `sudo()` en controladores debe limitarse al record mínimo necesario y filtrar antes de
  devolver datos.
- Tokens de acceso público se comparan con `odoo.tools.consteq` (nunca `==`; patrón
  portal — evita timing attacks).
- Rutas `type='json'` públicas requieren autenticación funcional alternativa (en 16 el
  tipo es `'json'`, no `'jsonrpc'`).

## Campos sensibles
- Contraseñas/tokens con `groups=` en el campo y/o `password=True` en la vista.
- PII con `groups=` por campo cuando solo un rol debe leerla; no expuesta en
  vistas/portal sin control de acceso.
- Credenciales en `res.company` con `groups='base.group_system'` (patrón
  `l10n_pe_edi_provider_username/password` en 16 EE) o en `ir.config_parameter`
  solo con acceso de administrador.

## Adjuntos y binarios
- `ir.attachment` hereda seguridad del `res_model/res_id`; enlaza al documento correcto.
- Evita adjuntos huérfanos accesibles por URL.

> Vulnerabilidades del entorno (CVEs de dependencias, versión de Python) se documentan
> en el `CLAUDE.md` del entorno, no aquí: este documento cubre el **código** del módulo.
