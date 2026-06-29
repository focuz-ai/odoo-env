# EDI e integraciones con autoridades fiscales (Odoo EE)

Estándar para módulos que emiten o transmiten documentos electrónicos a una autoridad
fiscal u OSE. Esta guía cubre el framework de envío, seguridad, idempotencia y tests.

## Framework de envío

- Nuevos EDI deben colgar de `account.move.send`.
- No inventes un `account.edi.format` nuevo si el flujo ya puede vivir como extra EDI.
- Usa hooks por proveedor y callbacks de aplicabilidad por movimiento.

## Coexistencia

- Evita el doble envío del mismo documento.
- Si conviven localizaciones legacy y nuevas, el gate de aplicabilidad debe ser claro.
- La migración debe documentar cuándo se sigue usando el mecanismo legacy y por qué.

## Firma y proveedor

- Reutiliza `certificate` para firma digital.
- Mantén un dispatch por provider/operación.
- No embebas credenciales en sitios no seguros.

## Durabilidad e idempotencia

- Persistir estado entre round-trips cuando el proveedor lo requiera.
- Reintentos deben ser idempotentes.
- Si el proveedor dice “ya procesado”, re-valida identidad antes de aceptar.

## Auditoría

- Un record por interacción externa.
- Conserva request/response, estado y timestamps.
- Los adjuntos deben quedar vinculados al documento correcto.

## Seguridad

- `data/neutralize.sql` para no-producción cuando aplique.
- Credenciales en `res.company` o `ir.config_parameter` solo con acceso de admin.
- Entorno demo/test/prod debe ser explícito.

## Tests

- Payloads de regulador con golden-file.
- Mockea la función de transporte, no `requests` directo.
- Los tests reales contra el servicio externo van separados.
