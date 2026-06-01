# Git guidelines — Odoo 18.0

> Fuente oficial: https://www.odoo.com/documentation/18.0/contributing/development/git_guidelines.html
>
> Estas son las convenciones **estilo Odoo upstream** (commits con `[TAG]`), útiles al
> contribuir a community/enterprise o a los repos del entorno. El flujo Spec-Driven de
> los módulos focuz-ai usa **Conventional Commits** con `Refs: <ticket>` (lo aplica
> `/odoo-commit`); no mezcles ambos estilos en un mismo repo.

## Formato de mensaje de commit
```
[TAG] module: short description (ideally < 50 chars)

Long description explaining WHY the change was made,
including rationale and technical decisions.

References: task-123, Fixes #123, opw-123
```

Principios clave:
- **Enfócate en el POR QUÉ, no en el QUÉ** — el diff muestra qué cambió.
- El header debe formar una oración válida: "if applied, this commit will [header]".
- **Un módulo por commit** (permite reverts independientes).
- Usa nombres técnicos de módulo, no funcionales.

## Tags de commit
| Tag | Uso |
|-----|-----|
| `[FIX]` | Bug fixes |
| `[IMP]` | Mejoras incrementales (el más común) |
| `[ADD]` | Nuevos módulos |
| `[REF]` | Refactoring de features |
| `[REM]` | Eliminar código/vistas/módulos muertos |
| `[REV]` | Revertir commits |
| `[MOV]` | Mover archivos (preserva historial) |
| `[REL]` | Commits de release |
| `[MERGE]` | Merge commits y forward ports |
| `[CLA]` | Firma del CLA |
| `[I18N]` | Cambios en traducciones |
| `[PERF]` | Mejoras de performance |
| `[CLN]` | Limpieza de código |
| `[LINT]` | Pasadas de linting |

## Nombrado de ramas
```
<base-branch>-<descripcion>     # 18.0-fix-invoice-discount, master-improve-stock
<base-branch>-<descripcion>-<handle>   # empleados de Odoo
```

## Ejemplo
```
[FIX] sale: correct discount calculation on multi-line orders

When applying a global discount to orders with multiple lines, the
discount was applied twice. Moves all discount logic to _compute_amount
to ensure single computation.

Fixes #12345
```

## PR guidelines
1. Base branch: `master` para features, `X.0` para bug fixes.
2. Título del PR: mismo formato que el commit principal.
3. Descripción: contexto, screenshots si aplica, pasos de testing.
4. Firmar el CLA antes de contribuir.
5. Habilitar "Allow edits from maintainer".
