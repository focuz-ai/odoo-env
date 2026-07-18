# Migración de módulos entre series — destino Odoo 18.0

> Esto es migrar el **código** de un módulo de una serie anterior a **18.0**. Es distinto
> de las migraciones **intra-versión** de esquema/datos (`migrations/<version>/`, ver
> [conventions.md](conventions.md) §Versionado y [testing.md](testing.md)).

## Principios
- **Un salto de serie a la vez** (o16→o17→o18), no de golpe: cada salto tiene su
  conjunto de cambios y OpenUpgrade asume saltos consecutivos.
- **No inventes APIs**: ante cualquier duda, verifica la firma/el patrón en el fuente
  18.0 de este entorno (`odoo/`, `odoo-enterprise/` — solo lectura).
- **Cierra con los gates normales** apuntando a 18.0: `/odoo-verify-build` (instala +
  tests + cobertura) y `/odoo-adversarial-review`. Las lentes cazan lo incorrecto para
  la serie (p.ej. el `odoo-tests-reviewer` marca QUnit nuevo: 18.0 usa HOOT).

## Fases
1. **Manifest**: `version` en formato corto Enterprise — al migrar de serie reinícialo a
   `1.0` (Odoo le antepone `18.0`; ver [conventions.md](conventions.md) §Versionado);
   revisa `depends` (módulos renombrados/fusionados/movidos a EE) y la declaración de
   `assets`.
2. **Python / ORM**: barre APIs deprecadas/removidas y adapta idioms a 18.0.
3. **Vistas XML**: adapta atributos y etiquetas removidas/renombradas.
4. **Frontend / assets / JS**: OWL 2, bundles y HOOT.
5. **Seguridad / datos**: revisa cambios en grupos/reglas core y registros `noupdate`.
6. **Migración de datos (DB)**: si el esquema/semántica cambió, script en
   `migrations/<version-destino-completa>/` (ver OpenUpgrade abajo).
7. **Tests**: migra al framework del destino (server y, sobre todo, JS) y vuélvelos verdes.
8. **Verifica**: `/odoo-verify-build` + `/odoo-adversarial-review` contra este entorno.

## Qué barrer al entrar a 18.0 (verifica cada patrón en el fuente)
- **Vistas**: `<tree>` → **`<list>`** (renombrada en 18.0; el RNG es `list_view.rng`);
  kanban con plantilla **`t-name="card"`** (antes `kanban-box`). `attrs`/`states` ya
  fueron removidos en 17.0 — si vienes de ≤16.0, resuélvelos en ese salto (atributos
  directos `invisible`/`readonly`/`required` con expresiones Python).
- **ORM/Python**: `@api.model_create_multi` exigido en overrides de `create`;
  `name_get()` → `_compute_display_name` (desde 17.0); firma de
  `_read_group`/`read_group`; helpers de fechas/tiempo de `odoo.tools`.
- **Frontend OWL**: OWL 2, `t-esc`/`t-raw` → `t-out`, registry/bundles vigentes; el
  framework de tests JS es **HOOT** (QUnit solo heredado en `static/tests/legacy/`).
  Ver [frontend-owl.md](frontend-owl.md) y [testing.md](testing.md).
- **Manifest/deps**: módulos que cambian de nombre o se absorben en core/EE entre series.

## OpenUpgrade
- Para entender qué cambió en los **modelos core** entre series, consulta OpenUpgrade
  (`https://github.com/OCA/OpenUpgrade`): sus análisis (`openupgrade_analysis`) y scripts
  de migración de datos por versión son la referencia de qué campos/modelos se movieron,
  renombraron o eliminaron.
- Para la migración de datos **de tu módulo**, escribe el script en
  `migrations/<version-destino-completa>/{pre,post,end}-*.py` usando los helpers de
  OpenUpgrade donde apliquen (renombrar columnas/XML-IDs, mover datos). El `version` del
  manifest debe quedar `>=` esa carpeta para que corra.

## Commit
- Migración de serie = commit `[MIG]` (ver [git-guidelines.md](git-guidelines.md)):
  `[MIG] <module>: migration to 18.0`.
