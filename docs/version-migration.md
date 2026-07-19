# Migración de módulos entre series Odoo

Esta guía cubre la migración de **código** entre series Odoo y las reglas de los
scripts `migrations/` del módulo.

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

## Scripts de migración (`migrations/`) y hooks

- Nombra la carpeta con la **versión corta** — igual al `version` del manifest sin la
  serie: el motor (`convert_version` en `odoo/modules/migration.py`) le antepone la
  serie activa, y el script acompaña al módulo al migrar de serie. Patrón core:
  manifest `'version': '3.3'` ↔ `migrations/3.3/` (`l10n_nl`).
- **No** fijes la serie completa (`16.0.x.y.z`) en la carpeta: queda clavada a esa
  serie y deja de disparar tras la migración de serie (misfire).
- Ojo con el motor: una carpeta con **dos o más puntos** se toma como versión completa
  tal cual. Con nuestro versionado `16.0.x.y.z`, la carpeta corta es `x.y` (dos
  componentes) y la migración exige bumpear al menos el minor; `x.y.z` a secas se
  interpretaría como versión completa antigua y no correría nunca.
- `migrations/0.0.0/` es especial: corre en **cualquier** cambio de versión (primera
  en `pre`, última en `post`/`end`).
- Retoques de datos XML → SQL sobre `ir_model_data`: flip de `noupdate` a `TRUE`,
  altas idempotentes con `INSERT … ON CONFLICT DO NOTHING` (patrón core:
  `l10n_nl/migrations/3.3/`, `l10n_it/migrations/15.0.0.3/`).
- Hooks **idempotentes y compartidos**: la misma función sirve de `post_init_hook`
  (instalación limpia) y se llama desde el script de `migrations/` (upgrade) —
  escríbela una sola vez, tolerante a re-ejecución.

## OpenUpgrade

**Cero OpenUpgrade en módulos EE**: ni dependencia ni imports (`openupgradelib`) —
el upgrade entre series es el servicio oficial de Odoo. Sus registros de análisis
sirven solo como **referencia** de qué cambió en el core; los scripts propios van en
`migrations/` del módulo.

## Commit

- Usa el tag `[MIG]`.
- Ejemplo: `[MIG] my_module: migration to 16.0`.
