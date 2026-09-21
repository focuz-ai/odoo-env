# EDI e integraciones con autoridades fiscales (Odoo EE)

Estándar para módulos que emiten o transmiten documentos electrónicos a una autoridad
fiscal u OSE. Esta guía cubre el framework de envío, seguridad, idempotencia y tests.

## Framework de envío

> **Cambio de la serie 20.0.** `l10n_pe_edi` **ya no usa el framework legacy
> `account.edi.format`**: se migró a `account.move.send`. El módulo `account_edi` sigue
> en el core, pero en 20.0 su único consumidor real es Ecuador (`l10n_ec_edi*`).

- **PE cuelga de `account.move.send`**: registra su EDI en `_get_all_extra_edis` con la
  clave `pe_ubl_2_1` y un callback de aplicabilidad `_is_pe_edi_applicable`
  (`l10n_pe_edi/models/account_move_send.py`). El XML lo genera
  `account.edi.xml.ubl_21` vía `account_edi_ubl_cii`.
- Extender PE = extender esos hooks — **no** forkear el módulo ni volver al legacy.
- Flujos EDI **nuevos** siguen el mismo patrón (`account.move.send` +
  `_get_all_extra_edis`), como `l10n_mx_edi`. No crees un `account.edi.format` nuevo.
- Los avisos previos al envío van en `_get_alerts` (patrón PE: bloquea los moves que no
  cumplen `_l10n_pe_edi_check_move_constraints`).

## Coexistencia y alcance PE

- Evita el doble envío del mismo documento.
- Si conviven localizaciones legacy y nuevas, el gate de aplicabilidad debe ser claro.
- La migración debe documentar cuándo se sigue usando el mecanismo legacy y por qué.
- El **Resumen Diario (RC)** de boletas NO existe en EE — solo la Comunicación de Baja
  (`RA-`). Si un cliente lo requiere, es desarrollo propio, no extensión de algo
  existente.

## Firma y proveedor

- Reutiliza el módulo `certificate` (`certificate.certificate`) para la firma
  digital; no re-modeles certificados.
- Provider en `res.company.l10n_pe_edi_provider`: `digiflow` (etiquetado «Estela
  (formerly Digiflow)»), `sunat` e `iap` (default). El dispatch en 20.0 es explícito —
  `_l10n_pe_edi_sign_invoices_iap` o, para los dos OSE por SOAP,
  `_l10n_pe_edi_sign_invoices_sunat_estela` — no el `getattr('..._%s' % provider)` de
  series anteriores. Un OSE nuevo = `selection_add` en el campo provider + su rama en
  ese dispatch.
- Credenciales del provider en `res.company` con `groups='base.group_system'`; no las
  embebas en sitios no seguros.

## Durabilidad e idempotencia

- El lock y los estados son **propios del módulo**, ya no del `account_edi` base:
  `lock_for_update()` (ORM, `odoo/orm/models.py`) sobre el move antes de firmar, y el
  campo computado `l10n_pe_edi_status` con `to_send/sent/cancelled`. No existe
  `blocking_level` en PE 20.0; los avisos van en `l10n_pe_edi_warnings` (JSON).
- Persistir estado entre round-trips cuando el proveedor lo requiera.
- Reintentos deben ser idempotentes.
- Anti-doble-envío PE: unicidad de filename (nombre del documento + VAT). Ante los
  códigos SUNAT `1033`/`4000` («ya registrado»), primero descarta que sea otro move
  ya `sent` con el mismo nombre/VAT (→ pedir resecuenciar) y si no, **re-FETCH del
  CDR** verificando identidad (serie-folio + tipo de documento) antes de aceptar el
  éxito.

## Errores del regulador

- Mapea los códigos CDR a **mensajes accionables**: el fuente mantiene un diccionario
  de 27 códigos → mensaje (`_l10n_pe_edi_get_cdr_error_messages`), más los genéricos de
  `_l10n_pe_edi_get_general_error_messages`.
- El dialecto SOAP de SUNAT difiere del de Estela/Digiflow: el namespace del fault se
  resuelve por proveedor (`fault_ns` en las credenciales) antes de parsear.
- SUNAT devuelve **HTTP 500 con SOAP válido** cuando el documento ya existe: parsea
  el fault antes de tratarlo como error de transporte.

## Auditoría

- Un record por interacción externa.
- Conserva request/response, estado y timestamps.
- Los adjuntos deben quedar vinculados al documento correcto.
- Attachments PE: **un solo zip** con el XML firmado + el CDR juntos; el correo usa
  un override que des-zipea, y el QR del PDF se reconstruye desde el XML del zip.

## Seguridad

- `data/neutralize.sql` para no-producción: además de voltear el flag sandbox,
  **anula las credenciales** (divergencia deliberada vs EE-PE, que solo voltea el
  flag — somos más estrictos).
- El flag de entorno de pruebas EDI lleva **`default=True`** (divergencia deliberada:
  EE-PE no lo trae; un módulo recién instalado nunca debe apuntar a producción).
- Credenciales en `res.company` o `ir.config_parameter` solo con acceso de admin.
- Entorno demo/test/prod debe ser explícito.

## Tests

- Payloads de regulador con golden-file.
- Mockea la función de transporte, no `requests` directo.
- Los tests reales contra el servicio externo van separados.
