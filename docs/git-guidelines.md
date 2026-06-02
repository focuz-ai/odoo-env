# Git guidelines — Odoo 18.0 (commits estilo Odoo)

> Fuente oficial: https://www.odoo.com/documentation/18.0/contributing/development/git_guidelines.html
>
> Aplica a contribuciones a Odoo community/enterprise y a los repos del entorno. El
> flujo Spec-Driven de los módulos focuz-ai usa **Conventional Commits** con
> `Refs: <ticket>` (lo aplica `/odoo-commit`); no mezcles ambos estilos en un repo.

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
| `[CLA]` | Firma del Contributor License Agreement |
| `[I18N]` | Cambios en archivos de traducción |
| `[PERF]` | Parches de rendimiento |
| `[CLN]` | Limpieza de código |
| `[LINT]` | Pasadas de linting |

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
