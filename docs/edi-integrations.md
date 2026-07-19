# EDI e integraciones con autoridades fiscales (Odoo EE)

Estándar para módulos que emiten o transmiten documentos electrónicos a una autoridad
fiscal u OSE. Esta guía cubre el framework de envío, seguridad, idempotencia y tests.

## Framework de envío

- **`l10n_pe_edi` sigue en el framework legacy `account.edi.format`** (formato
  `pe_ubl_2_1`, aplicabilidad vía `_get_move_applicability`). Extender PE = extender
  los hooks provider del legacy — **no** forkear el módulo ni migrarlo por tu cuenta.
- Flujos EDI **nuevos** (sin legacy que extender) cuelgan de `account.move.send`
  (+ `_get_all_extra_edis`), como `l10n_mx_edi`. No inventes un `account.edi.format`
  nuevo.
- Usa hooks por proveedor y callbacks de aplicabilidad por movimiento.

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
- Dispatch por provider vía `getattr`:
  `_l10n_pe_edi_sign_invoices_%s % provider` (digiflow/sunat/iap). Un OSE nuevo =
  `selection_add` en el campo provider + su método `_l10n_pe_edi_sign_invoices_<provider>`.
- Credenciales del provider en `res.company` con `groups='base.group_system'`; no las
  embebas en sitios no seguros.

## Durabilidad e idempotencia

- Asincronía/lock/estados vienen del `account_edi` base: `lock_for_update()` sobre
  documento+move antes de procesar, estados `to_send/sent/...` + `blocking_level`
  para reintentos.
- Persistir estado entre round-trips cuando el proveedor lo requiera.
- Reintentos deben ser idempotentes.
- Anti-doble-envío PE: unicidad de filename (nombre del documento + VAT). Ante los
  códigos SUNAT `1033`/`4000` («ya registrado»), primero descarta que sea otro move
  ya `sent` con el mismo nombre/VAT (→ pedir resecuenciar) y si no, **re-FETCH del
  CDR** verificando identidad (serie-folio + tipo de documento) antes de aceptar el
  éxito.

## Errores del regulador

- Mapea los códigos CDR a **mensajes accionables**: el fuente mantiene un diccionario
  de ~40 códigos → mensaje.
- Doble parser de SOAP faults: el dialecto de SUNAT difiere del de Estela/Digiflow.
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
