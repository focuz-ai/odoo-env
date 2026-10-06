# Git guidelines — Odoo 19.0 (commits estilo Odoo)

> Fuente oficial: https://www.odoo.com/documentation/19.0/contributing/development/git_guidelines.html
>
> **Estándar único de commits del proyecto**: este formato (`[TAG] module: …`) se usa
> en TODO — módulos focuz-ai y contribuciones a Odoo. No uses Conventional Commits.
> El ticket de Jira/Plane va en el footer de referencias (`Refs: <ticket>`); lo aplica
> `/odoo-commit`.

## Formato del mensaje
```
[TAG] module: short description (ideally < 50 chars)

Long description explaining WHY the change was made,
including rationale and feature context.

References (task-123, Fixes #123, Closes #123, opw-123, etc.)
```

## Principios
- **POR QUÉ, no QUÉ**: el diff ya muestra qué cambió; el mensaje explica el motivo y
  las decisiones técnicas. Sé verboso — el mensaje es tu documentación.
- El header debe formar una oración válida: *"if applied, this commit will [header]"*.
- Usa el **nombre técnico** del módulo, no el funcional.
- **Un módulo por commit** siempre que se pueda (permite reverts/cherry-picks limpios);
  evita cambios cross-módulo en un mismo commit.
- Evita descripciones de una palabra como "bugfix" o "improvements".
- Incluye **referencias**: nº de tarea, issues/PR de GitHub, tickets OPW.

## Tags
| Tag | Uso |
|-----|-----|
| `[FIX]` | Corrección de bugs |
| `[REF]` | Refactoring; features reescritas a fondo |
| `[ADD]` | Módulos nuevos |
| `[REM]` | Eliminar recursos (código muerto, vistas, módulos) |
| `[REV]` | Revertir commits |
| `[MOV]` | Mover archivos o código entre archivos (sin cambios funcionales) |
| `[REL]` | Commits de release (versiones major/minor) |
| `[IMP]` | Mejoras incrementales (el más común) |
| `[MERGE]` | Merge commits; forward-ports de fixes |
| `[MIG]` | Migración de un módulo entre series Odoo (`[MIG] module: migration to 19.0`) |
| `[CLA]` | Firma del Contributor License Agreement |
| `[I18N]` | Cambios en archivos de traducción |
| `[PERF]` | Parches de rendimiento |
| `[CLN]` | Limpieza de código |
| `[LINT]` | Pasadas de linting |

## Ramas y PR

- Programa siempre en `tmp.<serie>`.
- No commitees directo en `19.0` ni en `main`.
- El flujo es `tmp.<serie> -> staging.<serie> -> <serie> -> main`.
- La CI corre los tests solo en `tmp.*`.
- La CI de `tmp.19.0` prueba solo los addons afectados por el push (los cambiados y los
  del repo que dependen de ellos) que traen `tests/`. Corre la suite completa si cambian
  `.github/workflows/`, `requirements*.txt`, `checklog-odoo.cfg`, `pyproject.toml` u
  `openspec/config.yaml`, o sin diff utilizable; si el push no toca addons, no prueba nada.
- **Antes de cada push a `tmp.19.0`, suite completa en local**: `odoo-harness suite`
  (todos los addons del repo, con demo, en una BD desechable, sobre el commit ya hecho).
  En verde sella el árbol y el hook `pre-push` (`pre-commit install --hook-type
  pre-push`) deja empujar; sin sello, lo bloquea. Desde un worktree pasa `--conf` con una
  copia del `dev.conf` que apunte al worktree. Vale el sello de un árbol que solo difiere
  en `openspec/` (salvo `openspec/config.yaml`), `docs/`, `*.md` de la raíz o `.pot`.
  Nunca `--no-verify`.
- Cuando haya recursos de GitHub, lo idóneo es correr además la suite completa en los PR
  de release a `19.0` y `main`.
- Desde una rama o worktree propio (p.ej. `tmp.19.0-<ticket>`), empuja a `tmp.19.0`: la CI calcula
  `staging.<lo que sigue a tmp.>` como destino del auto-PR y `staging.19.0-<ticket>` no existe.
  `git fetch origin && git merge-base --is-ancestor origin/tmp.19.0 HEAD && git push origin HEAD:tmp.19.0`;
  luego borra la rama y el worktree.

## Config de git
Define `user.email` y `user.name` en tu git local antes de commitear:
```bash
git config --global user.email "<tu-email>"
git config --global user.name  "<tu-nombre>"
```

## Ejemplos (oficiales)
```
[REF] models: use `parent_path` to implement parent_store

This replaces the former modified preorder tree traversal (MPPT) with the
fields `parent_left`/`parent_right`[...]
```
```
[FIX] account: remove frenglish

[...]

Closes #22793
Fixes #22769
```
```
[FIX] website: remove unused alert div, fixes look of input-group-btn

Bootstrap's CSS depends on the input-group-btn element being the first/last
child of its parent. This was not the case because of the invisible
and useless alert.
```
