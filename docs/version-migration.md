# Migración de módulos entre series Odoo

Esta guía cubre la migración de **código** entre series Odoo, no las migraciones de
esquema/datos dentro de una misma serie.

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

## OpenUpgrade

Usa OpenUpgrade como referencia para cambios del core entre series. Si tu módulo
necesita script de datos, colócalo en `migrations/<version-destino-completa>/`.

## Commit

- Usa el tag `[MIG]`.
- Ejemplo: `[MIG] my_module: migration to 19.0`.
