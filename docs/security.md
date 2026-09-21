# Seguridad y permisos — Odoo 20.0 EE

## Reglas de acceso (`ir.access`)
> **Cambio de la serie 20.0.** `ir.model.access.csv` y el modelo `ir.rule` **ya no
> existen**: ACL y record rules se unifican en **`security/ir.access.csv`** (0 módulos
> del fuente 20.0 usan los antiguos; 226 en CE y 279 en EE usan el nuevo).

Columnas: `id,name,model_id,group_id/id,operation,domain`.

- **Todo modelo nuevo** necesita filas en `security/ir.access.csv`, declaradas en el
  `data` del manifest.
- `operation` es un subconjunto de **`crud`** (`r`, `cu`, `cud`, `crud`, …) — sustituye
  a las cuatro columnas `perm_read/write/create/unlink`. Da el mínimo por rol: `r` para
  quien solo consulta, no `crud` por defecto.
- `domain` (opcional) restringe la operación a los registros que lo cumplen: es lo que
  antes era una record rule, en la misma fila.
- **Con `group_id` = permiso** (otorga acceso a ese grupo); **sin `group_id` =
  restricción** (se aplica a todos). Los permisos se combinan con **OR** (basta que uno
  conceda) y las restricciones con **AND** (todas deben cumplirse), cf.
  `odoo/addons/base/models/ir_access.py`.
- Evita permisos para `base.group_public` y `base.group_portal` salvo que el caso de uso
  lo requiera explícitamente y tenga pruebas.

```csv
id,name,model_id,group_id/id,operation,domain
access_my_model_user,my.model user,my.model,my_module.group_my_user,r,
access_my_model_manager,my.model manager,my.model,my_module.group_my_manager,crud,
my_model_own_records,my.model: solo propios,my.model,,r,"[('user_id', '=', user.id)]"
```

## Grupos y privilegios
- Define grupos (`res.groups`) coherentes con los roles funcionales.
  XML ID `<modulo>_group_<nombre>`; las filas de `ir.access.csv`, `access_<modelo>_<rol>`.
- Los grupos cuelgan de un **`res.groups.privilege`** (contenedor de categoría): cada
  grupo enlaza `privilege_id` y forma escalera con `implied_ids`
  (user → manager → system; cf. `documents/security/security.xml`).
- Usa el `domain` de la fila donde el dato es sensible o multi-usuario.
- Para permisos complejos, el patrón EE es **fila amplia + dominio sobre un campo
  computado** de permiso: `[('user_permission', '!=', 'none')]` (documents),
  `[('user_has_access', '=', True)]` (knowledge).
- Las restricciones globales (sin grupo) deben ser simples y previsibles.

## Multi-compañía
- Campos `company_id` donde corresponda; `company_dependent=True` cuando el valor
  varía por compañía.
- Filas de `ir.access.csv` con dominio de compañía para evitar fugas entre compañías;
  el dominio estándar es `('company_id', 'in', company_ids)`, con `+ [False]` cuando
  el registro es compartible entre compañías.
- En relaciones entre modelos con compañía, usa `check_company=True` cuando aplique.
- Los datos globales sin `company_id` deben estar justificados.

## sudo()
- Cada `sudo()` debe estar **justificado**. Prohibido usarlo para saltarse ACL por
  comodidad o exponer datos a usuarios sin permiso.
- El patrón real del fuente no es «sudo mínimo» sino sudo + **re-imposición del
  control** antes de devolver datos: la API unificada es
  `record.check_access('read')` / `check_access('write')` (sustituye a
  `check_access_rights`/`check_access_rule`, extintos), o la verificación de
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
- Las rutas JSON son `type='jsonrpc'` (`type='json'` ya no existe: 216 rutas `jsonrpc`
  y 0 `json` en CE 20.0). Las rutas
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
