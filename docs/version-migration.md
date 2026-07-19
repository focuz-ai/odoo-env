# Migración de módulos entre series Odoo

Esta guía cubre la migración de **código** entre series Odoo y los scripts de
`migrations/` que acompañan los cambios de esquema/datos.

## Principios

- Migra un salto de serie a la vez.
- Trabaja siempre contra el estándar y el fuente del destino.
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

## Scripts de migración (`migrations/`)

- La carpeta usa la **versión corta** = el `version` del manifest sin la serie:
  `migrations/1.1/`. El motor antepone la serie en curso (`convert_version`) y evita
  re-ejecuciones al cambiar de serie. La forma completa (`19.0.x.y`) queda **fijada**
  a esa serie — no la uses para migraciones reutilizables.
- Carpeta especial `0.0.0`: corre en **cualquier** cambio de versión del módulo.
- Existen además el directorio hermano `upgrades/` (equivalente a `migrations/`) y
  `_force_upgrade_scripts` (fuerza scripts aunque el módulo no esté `to upgrade`).
- Idiomas reales de los scripts — SQL sobre `ir_model_data`:
  - flip a `noupdate=TRUE` para congelar data que el usuario editó;
  - `INSERT ... ON CONFLICT DO NOTHING` para dar XML-ID a registros existentes;
  - renombrado de XML-IDs entre módulos.
- Función **idempotente** en `hooks.py` reusada por el `post_init_hook` Y los scripts
  de upgrade (patrón `product_unspsc`/`l10n_pe_edi` para cargar CSVs).

## OpenUpgrade

**Cero OpenUpgrade en EE**: solo vale como referencia de análisis de los cambios del
core entre series, nunca como dependencia ni como fuente de scripts a copiar.

## Commit

- Usa el tag `[MIG]`.
- Ejemplo: `[MIG] my_module: migration to 19.0`.
