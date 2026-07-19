# EDI e integraciones con autoridades fiscales (Odoo 16.0 EE)

Estándar para módulos que emiten o transmiten documentos electrónicos a una autoridad
fiscal u OSE. Esta guía cubre el framework de envío, seguridad, idempotencia y tests.

## Framework de envío (Odoo 16 — NO `account.move.send`)

- En Odoo 16 el framework de EDI es `account.edi.format` (módulo `account_edi`), **no**
  `account.move.send` (ese wizard es de Odoo 17+; no existe en el fuente de esta
  versión — verificado en `odoo/addons/account/wizard/`).
- Un nuevo formato extiende `account.edi.format` e implementa según aplique:
  `_get_move_applicability`, `_needs_web_services`, `_is_compatible_with_journal`,
  `_check_move_configuration`.
- El disparo real es vía `account.move._post()` → crea `account.edi.document` →
  procesados por cron (`_compute_edi_web_services_to_process` en
  `odoo/addons/account_edi/models/account_move.py`).
- Referencia concreta en este repo: `enterprise/l10n_pe_edi/models/account_edi_format.py`
  (métodos `_l10n_pe_edi_*`) — cópia el patrón vigente de ahí antes de inventar hooks.
- No inventes un `account.edi.format` nuevo si el flujo ya puede vivir como extra EDI
  de uno existente.

## Coexistencia

- Evita el doble envío del mismo documento: filename EDI **determinista y único** por
  documento (constraint de unicidad si tu módulo genera el suyo). Ante «ya registrado»
  del OSE/SUNAT (códigos CDR `1033`/`4000` con el mismo filename), **re-fetch del CDR**
  en lugar de re-emitir (patrón `_l10n_pe_edi_post_invoice_web_service`); con filename
  distinto, deja subir el error de duplicado.
- Si conviven localizaciones legacy y nuevas, el gate de aplicabilidad
  (`_get_move_applicability`) debe ser claro.
- La migración debe documentar cuándo se sigue usando el mecanismo legacy y por qué.

## Firma y proveedor

- Reutiliza `certificate` para firma digital.
- Mantén un dispatch por provider/operación (ver el patrón `_l10n_pe_edi_*` como referencia).
- No embebas credenciales en sitios no seguros.

## Durabilidad e idempotencia

- Persistir estado entre round-trips cuando el proveedor lo requiera (`account.edi.document`).
- Reintentos deben ser idempotentes.
- Si el proveedor dice "ya procesado", re-valida identidad antes de aceptar.

## Auditoría

- Un record por interacción externa (`account.edi.document`).
- Conserva request/response, estado y timestamps.
- Los adjuntos deben quedar vinculados al documento correcto; conserva XML firmado y
  CDR juntos en un zip adjunto al move (patrón `_l10n_pe_edi_zip_edi_document`).

## Seguridad

- `data/neutralize.sql` para no-producción: estándar del proyecto — además de activar
  el flag de sandbox (lo único que hace el core), **anula las credenciales**
  (divergencia deliberada).
- Credenciales del proveedor en `res.company` con `groups='base.group_system'` en cada
  campo (patrón `l10n_pe_edi_provider_username/password` en 16 EE); nunca en campos
  sin `groups`.
- Entorno demo/test/prod debe ser explícito. El flag de entorno de pruebas EDI se
  declara con `default=True` (divergencia deliberada del proyecto: nadie emite a
  producción por omisión).

## Tests

- Payloads de regulador con golden-file.
- Mockea la función de transporte, no `requests` directo.
- Los tests reales contra el servicio externo van separados.
