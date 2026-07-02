# Migración de módulos entre series Odoo

Esta guía cubre la migración de **código** entre series Odoo, no las migraciones de
esquema/datos dentro de una misma serie.

## Principios

- Migra un salto de serie a la vez.
- Trabaja siempre contra el estándar y el fuente de **esta** versión (16.0) como destino.
- No inventes APIs por memoria.
- Cierra la migración con instalación, tests y revisión adversarial en el destino.

## Fases

1. Manifest.
2. Python y ORM.
3. Vistas XML.
4. Frontend, assets y tests JS.
5. Seguridad y datos.
6. Migración de datos si el esquema cambió.
7. Tests.
8. Verificación final.

## Qué barrer

- Decoradores y firmas removidas.
- Vistas y atributos obsoletos.
- Cambios de OWL o framework de tests JS.
- Módulos renombrados o fusionados.

## Específico al migrar HACIA Odoo 16.0

- Framework de tests JS destino: **QUnit**, no HOOT (HOOT llegó en 18; si el origen
  es una serie más nueva con HOOT, hay que reescribir a QUnit).
- EDI: el framework destino es `account.edi.format` (módulo `account_edi`); si el
  origen usa `account.move.send` (17+), hay que reescribir contra `account.edi.format`
  (ver [edi-integrations.md](edi-integrations.md)).
- `create` usa `@api.model_create_multi` (ya vigente desde antes de 16, sin cambio).

## OpenUpgrade

Usa OpenUpgrade como referencia para cambios del core entre series. Si tu módulo
necesita script de datos, colócalo en `migrations/<version-destino-completa>/`.

## Commit

- Usa el tag `[MIG]`.
- Ejemplo: `[MIG] my_module: migration to 16.0`.
