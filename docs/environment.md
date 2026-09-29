# Entorno: rutas y runtime (odools.toml + dev.conf + launch.json)

El sistema no mantiene su propio archivo de rutas. Se apoya en archivos que ya
existen en el entorno de desarrollo (`o19-env`):

| Fuente | Aporta | Uso |
|--------|--------|-----|
| `odools.toml` | `odoo_path` + `addons_paths` (community, enterprise, themes y `src/...`) | Explorar y reutilizar fuente |
| `config/<cliente>/dev.conf` | `addons_path` de runtime, conexión, `test_tags` | Config base para `odoo-bin -c` |
| `.vscode/launch.json` | BD destino, módulos `-u`, flags `--dev`, puerto | Levantar y depurar Odoo |

> La BD no se fija en el `dev.conf`. Cada target de `launch.json` elige su BD con
> `--db-filter` o `-d`. El `dev.conf` aporta `addons_path` + conexión + ajustes base.

## Reglas para agentes

- Las raíces de exploración salen de `odools.toml`.
- El runtime y los tests salen de `config/<cliente>/dev.conf` + `.vscode/launch.json`.
- No dupliques secretos ni rutas en docs fuera de sus archivos fuente.
- Si falta `odools.toml` o el `dev.conf` indicado, detente y avísalo.

## Gates desde un worktree

El `test_conf` de un repo (`openspec/config.yaml`) apunta a un `dev.conf` cuyo `addons_path` usa el checkout
principal del repo: un gate lanzado desde un worktree probaría el código del checkout principal. Para trabajar en un
worktree: copia el conf con la ruta del worktree (`config/<cliente>/dev-wt-<ticket>.conf`, no versionado), apunta
**temporalmente** `test_conf` a él, pasa `--repo <worktree>` al harness y **revierte `test_conf` antes de cada
commit**. Al terminar, empuja a `tmp.<serie>` (ver [git-guidelines.md](git-guidelines.md)) y borra el worktree,
la rama y el conf local.

## Versión de Odoo

La versión activa se deduce de `odools.toml` o de la rama del repo (`19.0`).
Los estándares específicos de esa versión viven en este `docs/`.

## Resolución de docs

Los agentes globales deben resolver primero `<raíz o19-env>/docs/<tema>.md`.
Mientras tanto, `~/.local/share/odoo-openspec/docs/<tema>.md` actúa como respaldo.

## Validación determinista

`scripts/check_env.py` valida `odools.toml` y el `dev.conf` sin leer secretos.
`odoo-doctor` debe correrlo como paso 0.
