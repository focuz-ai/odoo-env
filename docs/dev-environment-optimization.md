# Optimización del entorno de desarrollo Odoo

Guía de optimizaciones aplicables al ciclo de iteración día-a-día en `o16-env`. A
diferencia de otros documentos de `docs/` (estándar de código), esto es **anexo
operativo**: recomendaciones de tooling, no reglas de revisión de código.

> **Estado en este repo:** `.vscode/settings.json` (sección 5), `.pre-commit-config.yaml`
> (sección 8) y `package.json`/`prettier.config.cjs` (sección 9) ya están aplicados.
> El resto (`scripts/` de templates de DB, filestore cleanup, `pytest-odoo`) sigue
> siendo recomendación a evaluar, adaptada del entorno hermano `o19-env` donde sí
> está en uso.

## Tabla de contenido

1. [PostgreSQL en modo desarrollo](#1-postgresql-en-modo-desarrollo)
2. [`uv` como gestor de paquetes](#2-uv-como-gestor-de-paquetes)
3. [Templates de base de datos](#3-templates-de-base-de-datos)
4. [`--dev=xml,reload,qweb` en lugar de `--dev=all`](#4---devxmlreloadqweb)
5. [VSCode multi-root y exclusiones](#5-vscode-multi-root-y-exclusiones)
6. [Git fsmonitor + untracked cache](#6-git-fsmonitor--untracked-cache)
7. [`pytest-odoo` para tests](#7-pytest-odoo-para-tests)
8. [`pylint-odoo` (OCA) en pre-commit](#8-pylint-odoo-oca-en-pre-commit) ✅ aplicado
9. [Prettier para JS/XML/YAML/MD](#9-prettier-para-jsxmlyamlmd) ✅ aplicado

---

## 1. PostgreSQL en modo desarrollo

**Ganancia esperada:** 5-10× en tests/imports/instalación de módulos.

**Idea:** la DB de dev no necesita sobrevivir a un crash. Desactivar durabilidad
(`fsync`, `synchronous_commit`, `full_page_writes`) y subir memoria/paralelismo en el
Postgres de desarrollo (puerto **5454** en este entorno, ver `CLAUDE.md` →
Database Configuration).

Si Postgres corre en Docker (`docker-compose.override.yml` del contenedor local),
agregar al `command:` del servicio:

```yaml
command:
  - "postgres"
  - "-c"
  - "fsync=off"
  - "-c"
  - "synchronous_commit=off"
  - "-c"
  - "full_page_writes=off"
  - "-c"
  - "shared_buffers=2GB"
  - "-c"
  - "work_mem=64MB"
```

`docker compose restart` **no** aplica cambios en `command:` — hay que recrear el
contenedor (`down` → `up -d`).

**Tradeoffs:** si el contenedor crashea durante un write, la DB queda corrupta
(aceptable en dev, no en producción). No aplicar este override fuera de desarrollo.

---

## 2. `uv` como gestor de paquetes

**Ganancia esperada:** 10-100× en `pip install`, especialmente al alternar versiones
de Python (ver recomendación de Python 3.12 para este repo en `CLAUDE.md`).

`uv` es un drop-in replacement de `pip` escrito en Rust por Astral. Mismo
`requirements.txt`, misma sintaxis, misma resolución de dependencias.

```bash
source .venv/bin/activate
pip install uv

# Sustituye pip por uv pip:
uv pip install -r odoo/requirements.txt
uv pip install -r requirements.txt
uv pip check
```

---

## 3. Templates de base de datos

**Problema:** crear DBs limpias para probar requiere instalar `base, web, l10n_pe`
cada vez (varios minutos).

**Solución:** instalar una sola vez en un template Postgres marcado como tal, y
luego clonar (`CREATE DATABASE ... TEMPLATE ...`) — toma segundos. Este entorno no
tiene scripts para esto todavía; si se adopta, crear equivalentes de
`db-template-create.sh` / `db-clone-from-template.sh` bajo un `scripts/` propio.

Detalles técnicos: el template se marca con `datistemplate=true` y
`ALLOW_CONNECTIONS=false`; Postgres requiere que el template esté sin conexiones
activas durante el `CREATE DATABASE ... TEMPLATE`.

---

## 4. `--dev=xml,reload,qweb`

`--dev=all` incluye `assets`, que recompila JS/SCSS/XML en cada request — costoso.

```bash
# En lugar de:
python odoo/odoo-bin -c config/<cliente>/dev.conf --dev=all

# Usa:
python odoo/odoo-bin -c config/<cliente>/dev.conf --dev=xml,reload,qweb
```

Cubre la mayoría de los casos de dev Python/XML. Activa `--dev=all` solo cuando
estés tocando JS/OWL/SCSS.

---

## 5. VSCode multi-root y exclusiones ✅ aplicado

`odools.toml` en este entorno indexa `enterprise/` (764+ módulos) + `design-themes/`
para todos los clientes simultáneamente. Odoo IDE reindexa todo en cada cambio.

**Ya aplicado** en [`.vscode/settings.json`](../.vscode/settings.json):
`files.watcherExclude`, `search.exclude` y `files.exclude` excluyen
`enterprise/`, `design-themes/`, `vendor/`, `.venv/`, `__pycache__/`, `.ruff_cache/`
y `*.pyc`.

> Las exclusiones de `search` no impiden que Odoo IDE encuentre símbolos — solo
> afectan al `Ctrl+Shift+F` global. El scope de indexación real del Odoo IDE vive
> en `pyrightconfig.json`, no aquí.

---

## 6. Git fsmonitor + untracked cache

`enterprise/` tiene cientos de directorios; `git status` puede tomar varios segundos.

```bash
git -C odoo config core.fsmonitor true
git -C odoo config core.untrackedCache true
git -C enterprise config core.fsmonitor true
git -C enterprise config core.untrackedCache true
git -C design-themes config core.fsmonitor true
git -C design-themes config core.untrackedCache true
```

---

## 7. `pytest-odoo` para tests

Mejor DX que `--test-enable`: filtros más finos, output legible, integración con
VSCode Test Explorer. No está instalado en este entorno (`requirements.txt` solo
trae `pytest`, no `pytest-odoo`).

```bash
pip install pytest-odoo
pip install -e ./odoo   # pytest-odoo requiere que 'odoo' sea importable

pytest --odoo-database=test_db -k "test_invoice_discount"
pytest --odoo-database=test_db --odoo-config=config/<cliente>/dev.conf
```

---

## 8. `pylint-odoo` (OCA) en pre-commit

Ruff atrapa errores Python genéricos. `pylint-odoo` atrapa antipatrones específicos
de Odoo (manifests con keys deprecadas, `sql-injection` en queries crudas,
`method-required-super`, imports relativos en addons, etc.).

**Configuración actual:** [`.pre-commit-config.yaml`](../.pre-commit-config.yaml) en
la raíz del entorno — `pre-commit-hooks` (higiene básica) + `ruff-pre-commit`
(`ruff --fix` + `ruff-format`) + `pylint-odoo` (`--enable=odoolint`, solo reglas
Odoo-específicas). Excluye `odoo/`, `enterprise/`, `design-themes/`, `vendor/`,
`.venv/`, `*/migrations/*`. Reglas OCA que **no** aplican a `focuz-ai` están
desactivadas (`manifest-required-author`, `missing-readme`, `manifest-author-string`,
`manifest-maintainers-list`).

```bash
pip install pre-commit
pre-commit install                  # instala el hook en .git/hooks/pre-commit
pre-commit run                      # sobre staged
pre-commit run --files <archivo>    # sobre archivos específicos
```

> **Primera pasada:** no correr `--all-files` de golpe sobre código existente — los
> hooks de auto-fix reformatearían toda la base. Mejor dejar que actúe solo sobre
> archivos modificados, e ir limpiando módulo por módulo cuando los toques.

---

## 9. Prettier para JS/XML/YAML/MD

Ruff/`pylint-odoo` solo cubren Python. Para el resto de formatos que aparecen en un
módulo Odoo (XML de vistas, JS/OWL, SCSS, YAML, Markdown), Prettier da formato
consistente y determinista.

**Configuración actual:** [`package.json`](../package.json) +
[`prettier.config.cjs`](../prettier.config.cjs) en la raíz — `printWidth: 120`
(igual que `ruff.toml`), plugin `@prettier/plugin-xml` para vistas/manifest XML.
Wiring de VSCode (format-on-save por lenguaje) en `.vscode/settings.json`.

```bash
npm install                 # instala prettier + @prettier/plugin-xml (una vez)
npm run format               # formatea todo src/dev y src/projects
npm run format:file -- <archivo>   # un archivo puntual
```

> Requiere la extensión `esbenp.prettier-vscode` en VSCode para format-on-save;
> `charliermarsh.ruff` sigue siendo el formatter para `.py` (sin conflicto, cada uno
> cubre lenguajes distintos).

**Gotcha verificado — `.gitignore` bloqueaba el propósito real de este script.**
Prettier respeta `.gitignore` por defecto, y este entorno gitignorea en bloque
`src/dev/*` y `src/projects/*` (cada módulo/cliente es un repo clonado aparte, no
trackeado por `o16-env`). Sin corregirlo, `npm run format` reportaba éxito sin
formatear nada real (`prettier --file-info` mostraba `"ignored": true` para
cualquier archivo bajo esas rutas). Fix aplicado: [`.prettierignore`](../.prettierignore)
propio + `--ignore-path .prettierignore` explícito en los scripts de
`package.json` y en `prettier.ignorePath` de `.vscode/settings.json` — así Prettier
deja de heredar las reglas de git y sí llega al código real. Verificado con
`npx prettier --ignore-path .prettierignore --check "src/projects/<cliente>/*"`.
