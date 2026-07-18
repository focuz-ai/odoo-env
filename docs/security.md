# Seguridad y permisos — Odoo 18.0 EE

## Reglas de acceso (ACL)
- **Todo modelo nuevo** necesita reglas en `ir.model.access.csv`.
- Permisos **mínimos por grupo**: no des `1,1,1,1` a todos por defecto.
- Separa lectura/escritura/creación/borrado según el rol real.
- Evita ACL para `base.group_public`/`base.group_portal` salvo que el caso de uso lo
  requiera explícitamente y tenga pruebas de acceso.

## Grupos y record rules
- Define grupos (`res.groups`) coherentes con los roles funcionales.
  XML ID `<modulo>_group_<nombre>`; record rules `<modelo>_rule_<grupo>`.
- Usa **record rules** donde el dato es sensible o multi-usuario (global vs por-grupo).
- Revisa `perm_read/write/create/unlink` de cada regla.
- Las record rules globales deben ser simples y previsibles; si mezclan roles funcionales,
  divídelas por grupo para facilitar auditoría.

## Multi-compañía
- Campos `company_id` donde corresponda; `company_dependent=True` cuando el valor
  varía por compañía.
- Record rules de compañía (`company_ids`) para evitar fugas entre compañías.
- En relaciones entre modelos con compañía, usa `check_company=True` cuando aplique y
  valida los dominios de vistas para no permitir seleccionar registros de otra compañía.
- Los datos globales sin `company_id` deben estar justificados; no uses ausencia de
  compañía para esquivar reglas multi-compañía.

## sudo()
- Cada `sudo()` debe estar **justificado**. Prohibido usarlo para saltarse ACL por
  comodidad o exponer datos a usuarios sin permiso.

## Controladores e inyección
- `@http.route`: `auth='public'` y `csrf=False` solo cuando esté justificado.
- Valida `request.params`; nunca confíes en la entrada del usuario.
- Sin `eval`/`safe_eval` sobre entrada de usuario; SQL siempre parametrizado
  (ver [orm-performance.md](orm-performance.md)).
- `sudo()` en controladores debe limitarse al record mínimo necesario y filtrar antes de
  devolver datos. Nunca devuelvas recordsets completos serializados sin control de campos.
- Rutas `type='json'` públicas requieren autenticación funcional alternativa (token firmado,
  webhook secret, firma HMAC, etc.) y pruebas de rechazo.

## Campos sensibles
- Contraseñas/tokens con `groups=` y/o `password=True`.
- PII no expuesta en vistas/portal sin control de acceso.
- Credenciales en `res.company` o `ir.config_parameter` solo con acceso de administrador;
  no las copies a campos computados visibles para usuarios funcionales.

## Adjuntos y binarios
- `ir.attachment` hereda seguridad del `res_model/res_id`: asegúrate de enlazarlo al
  documento correcto y no a modelos genéricos si contiene PII, XML fiscal o credenciales.
- Adjuntos generados por integraciones externas deben tener nombre, mimetype y dueño
  funcional claros; evita adjuntos huérfanos accesibles por URL.

> Vulnerabilidades del entorno (CVEs de dependencias, versión de Python) se documentan
> en el `CLAUDE.md` del entorno, no aquí: este documento cubre el **código** del módulo.
