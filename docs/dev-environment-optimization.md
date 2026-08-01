# Optimización del entorno de desarrollo Odoo

Guía consolidada de optimizaciones aplicadas a este entorno (`omaster-env`) para acelerar el ciclo de iteración día-a-día. Las primeras 3 secciones ya están aterrizadas; el resto son recomendaciones listas para aplicar.

> **Contexto:** desarrollo Odoo 19 EE en WSL2, Postgres 17 en Docker en el host Windows.

## Tabla de contenido

1. [PostgreSQL en modo desarrollo](#1-postgresql-en-modo-desarrollo) ✅ aplicado
2. [`uv` como gestor de paquetes](#2-uv-como-gestor-de-paquetes) ✅ aplicado
3. [Templates de base de datos](#3-templates-de-base-de-datos) ✅ aplicado
4. [`--dev=xml,reload,qweb` en lugar de `--dev=all`](#4---devxmlreloadqweb)
5. [VSCode multi-root y exclusiones](#5-vscode-multi-root-y-exclusiones)
6. [Git fsmonitor + untracked cache](#6-git-fsmonitor--untracked-cache)
7. [Filestore en SSD/tmpfs](#7-filestore-en-ssdtmpfs)
8. [`pytest-odoo` para tests](#8-pytest-odoo-para-tests)
9. [`pylint-odoo` (OCA) en pre-commit](#9-pylint-odoo-oca-en-pre-commit)
10. [Hot reload de Python (`--dev=reload`)](#10-hot-reload-de-python)

---

## 1. PostgreSQL en modo desarrollo

**Ganancia esperada:** 5-10× en tests/imports/instalación de módulos.

**Idea:** la DB de dev no necesita sobrevivir a un crash. Desactivamos durabilidad (`fsync`, `synchronous_commit`, `full_page_writes`) y subimos memoria/paralelismo.

### Configuración aplicada

Archivo: `/mnt/d/Projects/Docker/pg_odoo_19/docker-compose.override.yml`

```yaml
services:
  postgres:
    restart: always
    ports:
      - "${DB_PORT}:5432"
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 8G
        reservations:
          cpus: '1'
          memory: 2G
    command:
      - "postgres"
      # --- Desarrollo: desactivar durabilidad para máxima velocidad ---
      - "-c"
      - "fsync=off"
      - "-c"
      - "synchronous_commit=off"
      - "-c"
      - "full_page_writes=off"
      # --- Memoria ---
      - "-c"
      - "shared_buffers=2GB"
      - "-c"
      - "work_mem=64MB"
      - "-c"
      - "effective_cache_size=6GB"
      - "-c"
      - "maintenance_work_mem=256MB"
      # --- Conexiones y paralelismo ---
      - "-c"
      - "max_connections=200"
      - "-c"
      - "max_parallel_workers=4"
      - "-c"
      - "max_worker_processes=8"
      - "-c"
      - "max_parallel_workers_per_gather=2"
      # --- WAL y checkpoints ---
      - "-c"
      - "max_wal_size=1GB"
      - "-c"
      - "min_wal_size=512MB"
      - "-c"
      - "checkpoint_completion_target=0.9"
      # --- Planner (SSD/NVMe) ---
      - "-c"
      - "random_page_cost=1.1"
      - "-c"
      - "effective_io_concurrency=200"
```

### Aplicar cambios

`docker compose restart` **no** sirve para cambios en `command:` — mantiene los args originales del contenedor. Hay que recrearlo:

```bash
cd /mnt/d/Projects/Docker/pg_odoo_19
docker compose down postgres
docker compose up -d postgres
```

> ⚠️ **Siempre `down` → `up -d`**, nunca confiar en el "Recreate" implícito de `up -d`.

### Verificar que se aplicaron

```bash
PGPASSWORD=odoo psql -h 127.0.0.1 -p 5435 -U odoo -d postgres -c \
  "SELECT name, setting FROM pg_settings WHERE name IN
   ('fsync','synchronous_commit','full_page_writes','shared_buffers',
    'work_mem','effective_cache_size','max_worker_processes',
    'max_parallel_workers','random_page_cost') ORDER BY name;"
```

### Tradeoffs

- ❌ **Si el contenedor crashea durante un write, la DB queda corrupta.** Aceptable en dev — recreas con un template (sección 3).
- ❌ **No aplicar este override en producción.**
- ✅ Imports masivos, `init` de módulos pesados (account, sale, l10n_pe) y suites de tests bajan de minutos a decenas de segundos.

---

## 2. `uv` como gestor de paquetes

**Ganancia esperada:** 10-100× en `pip install`, especialmente al alternar versiones de Python.

`uv` es un drop-in replacement de `pip` escrito en Rust por Astral. Mismo `requirements.txt`, misma sintaxis, misma resolución de dependencias.

### Instalación (una sola vez)

```bash
source .venv/bin/activate
pip install uv
```

### Uso

Sustituye `pip` por `uv pip`:

```bash
uv pip install -r odoo/requirements.txt
uv pip install -r requirements.txt
uv pip check
uv pip install ipython
```

### Benchmark real

Verificar dependencias del proyecto (`pip check` vs `uv pip check`):

| Comando | Tiempo |
|---------|--------|
| `pip check` (44 paquetes) | ~3-8s |
| `uv pip check` (44 paquetes) | ~0.2s |

### Cuándo NO usar `uv`

- Si necesitas plugins de pip muy específicos (raro).
- Si tu CI ya tiene cache fina de pip y no quieres tocarlo.

---

## 3. Templates de base de datos

**Problema:** crear DBs limpias para probar requiere instalar `base, web, l10n_pe` cada vez (varios minutos).

**Solución:** instalar una sola vez en un template Postgres marcado como tal, y luego clonar (`CREATE DATABASE ... TEMPLATE ...`) — toma segundos.

### Scripts disponibles

| Script | Función |
|--------|---------|
| `scripts/db-template-create.sh` | Crea/recrea un template con módulos pre-instalados |
| `scripts/db-clone-from-template.sh` | Clona una DB nueva desde un template existente |

### Crear el template `tpl_l10n_pe`

```bash
# Defaults: TEMPLATE=tpl_l10n_pe, MODULES=base,web,l10n_pe, CONFIG=config/l10n-pe/dev.conf
./scripts/db-template-create.sh
```

Con argumentos personalizados:

```bash
# Template con l10n_pe + EDI
./scripts/db-template-create.sh tpl_l10n_pe_edi base,web,l10n_pe,l10n_pe_edi

# Template para otro cliente
./scripts/db-template-create.sh tpl_etl base,web,sale,purchase config/ETL/dev.conf
```

### Clonar una DB desde el template

```bash
# Crea pe_test_20260509 a partir de tpl_l10n_pe (segundos en lugar de minutos)
./scripts/db-clone-from-template.sh tpl_l10n_pe pe_test_$(date +%Y%m%d)

# Iniciar Odoo contra la DB clonada
python odoo/odoo-bin -c config/l10n-pe/dev.conf -d pe_test_20260509
```

### Detalles técnicos

- El template se marca con `datistemplate=true` y `ALLOW_CONNECTIONS=false` para evitar escrituras accidentales.
- Postgres requiere que el template esté **sin conexiones activas** durante el `CREATE DATABASE ... TEMPLATE`. El script de clonación maneja esto automáticamente activando/desactivando `ALLOW_CONNECTIONS`.
- Recrear el template implica matar conexiones, dropearlo y volver a `-i módulos`. Toma lo mismo que la primera instalación.

### Cuándo recrear el template

- Cuando subes versión menor de Odoo (`git pull` en `odoo/`).
- Cuando agregas un módulo "core" del cliente (l10n_pe_edi, sale, etc.).
- Cuando aplicas migraciones que cambian el esquema base.

---

## 4. `--dev=xml,reload,qweb`

`--dev=all` incluye `assets`, que recompila JS/SCSS/XML en cada request — muy costoso.

```bash
# En lugar de:
python odoo/odoo-bin -c config/l10n-pe/dev.conf --dev=all

# Usa:
python odoo/odoo-bin -c config/l10n-pe/dev.conf --dev=xml,reload,qweb
```

**Cubre el 95% de los casos de dev Python/XML.** Activa `--dev=all` solo cuando estés tocando JS/OWL/SCSS.

---

## 5. VSCode multi-root y exclusiones

Tu workspace actual indexa los **764 módulos de `enterprise/`** + `industry/` + `design-themes/` para todos los clientes simultáneamente. Odoo IDE reindexa todo en cada cambio.

### Opción A: workspace por cliente (más limpio)

Crear `.code-workspace` por cliente, con su `odools.toml` apuntando solo al `addons_path` que ese cliente necesita.

### Opción B: exclusiones globales (más rápido de aplicar)

Agregar a `.vscode/settings.json`:

```json
{
  "files.watcherExclude": {
    "**/enterprise/**": true,
    "**/industry/**": true,
    "**/design-themes/**": true,
    "**/.venv/**": true,
    "**/__pycache__/**": true,
    "**/*.pyc": true
  },
  "search.exclude": {
    "enterprise": true,
    "industry": true,
    "design-themes": true,
    "vendor": true
  },
  "files.exclude": {
    "**/__pycache__": true,
    "**/.ruff_cache": true
  }
}
```

> Las exclusiones de `search` no impiden que Odoo IDE encuentre símbolos — solo afectan al `Ctrl+Shift+F` global.

---

## 6. Git fsmonitor + untracked cache

`enterprise/` tiene 764 directorios. `git status` puede tomar 3-5s.

```bash
git -C odoo config core.fsmonitor true
git -C odoo config core.untrackedCache true
git -C enterprise config core.fsmonitor true
git -C enterprise config core.untrackedCache true
git -C design-themes config core.fsmonitor true
git -C design-themes config core.untrackedCache true
```

**Resultado:** `git status` baja a < 100ms.

---

## 7. Filestore en SSD/tmpfs

### Estado actual

Tu filestore vive en `~/.local/share/Odoo/filestore/` sobre WSL2 ext4 (`/dev/sdf` SSD). **Ya estás en el filesystem más rápido disponible** — mover a otro SSD no daría ganancia.

Lo que sí tiene impacto:

#### A. Limpieza de filestores huérfanos

Filestores cuya DB ya no existe siguen ocupando disco. Script para detectarlos y borrarlos:

```bash
# Dry-run (lista sin borrar)
./scripts/clean-orphan-filestores.sh

# Borrado real (requiere confirmar pasando --apply)
./scripts/clean-orphan-filestores.sh --apply

# Con otra config / data_dir
./scripts/clean-orphan-filestores.sh --config config/ETL/dev.conf --data-dir /custom/path
```

El script:
1. **Auto-detecta TODAS las instancias Postgres** en `/mnt/d/Projects/Docker/pg_odoo_*` (lee `.env` de cada una).
2. Une la lista de DBs de todas las instancias (incluyendo templates).
3. Marca como huérfano solo los filestores cuyo nombre NO existe en NINGUNA instancia.
4. Lista ordenado por tamaño.
5. Solo borra si pasas `--apply`.

> **Por qué chequear todas las instancias:** un filestore puede pertenecer a una DB que vive en `pg_odoo_18` (puerto 5434) aunque no esté en `pg_odoo_19` (puerto 5435). Sin esta verificación, podrías borrar filestores en uso.

Para sobreescribir la auto-detección:

```bash
# Solo verificar contra dos instancias específicas
./scripts/clean-orphan-filestores.sh \
    --instance 127.0.0.1:5432:odoo:odoo \
    --instance 127.0.0.1:5435:odoo:odoo

# Cambiar el glob de auto-detección
./scripts/clean-orphan-filestores.sh --instances-glob "/otra/ruta/pg_*"
```

> **Cuándo correr:** después de eliminar DBs viejas, después de migrar a una nueva instancia de Postgres, periódicamente como mantenimiento.

#### B. Tmpfs para DBs de test efímeras

Si abusas del workflow de templates (sección 3) y creas DBs descartables, puedes apuntar `data_dir` a tmpfs para evitar I/O de disco:

```bash
# Crear data_dir en tmpfs (16GB disponibles en /dev/shm)
mkdir -p /dev/shm/odoo-test-data

# Usar via flag CLI (sin tocar dev.conf)
python odoo/odoo-bin -c config/l10n-pe/dev.conf \
    -d test_run_$$ \
    --data-dir=/dev/shm/odoo-test-data
```

⚠️ Se pierde al reiniciar — solo para tests. No usar para DBs que quieras preservar.

#### C. Per-client `data_dir` (organizativo)

Para separar filestores por cliente (más fácil de respaldar/migrar individualmente), agrega a cada `config/<cliente>/dev.conf`:

```ini
data_dir = /home/focuz/odoo-data/l10n-pe
```

⚠️ **Migración manual requerida** si ya tienes filestores en `~/.local/share/Odoo/filestore/`. Mover los directorios de las DBs activas al nuevo `data_dir` antes de arrancar Odoo.

---

## 8. `pytest-odoo` para tests

Mejor DX que `--test-enable`: filtros más finos, output legible, integración con VSCode Test Explorer.

### Instalación

```bash
uv pip install pytest-odoo

# pytest-odoo requiere que el paquete `odoo` sea importable:
uv pip install -e ./odoo
```

> El editable install agrega Odoo como namespace package al `.venv`. No interfiere con el flujo normal de `python odoo/odoo-bin ...`.

### Uso

```bash
# Correr tests específicos
pytest --odoo-database=test_db -k "test_invoice_discount"

# Filtrar por config
pytest --odoo-database=test_db --odoo-config=config/l10n-pe/dev.conf

# Pasar flags a Odoo
pytest --odoo-database=test_db --odoo-extra workers=0 --odoo-extra log-level=test
```

Combinado con la sección 3 (templates):

```bash
./scripts/db-clone-from-template.sh tpl_l10n_pe test_run_$$
pytest --odoo-database=test_run_$$ -k "test_l10n_pe"
```

---

## 9. `pylint-odoo` (OCA) en pre-commit

Ruff atrapa errores Python genéricos. `pylint-odoo` atrapa antipatrones específicos de Odoo:
- Manifests con keys deprecadas o superfluas (`description`, `installable: True`)
- `sql-injection` en queries crudas
- `method-required-super` (override sin `super()`)
- `attribute-string-redundant`
- `external-request-timeout`
- Imports relativos en addons
- etc.

### Configuración actual

Archivo: [`.pre-commit-config.yaml`](../.pre-commit-config.yaml). Resumen:

- **`pre-commit-hooks` v6.0.0** — higiene básica (trailing whitespace, EOF, check-xml, large files).
- **`ruff-pre-commit` v0.15.12** — Ruff con `--fix` + `ruff-format`.
- **`pylint-odoo` v10.0.2** — solo reglas Odoo-específicas (`--enable=odoolint`), sin las generales (ya cubiertas por Ruff).
- **Excluido:** `odoo/`, `enterprise/`, `industry/`, `design-themes/`, `vendor/`, `.venv/`, `*/migrations/*`.
- **Reglas OCA-específicas desactivadas** (porque eres `focuz-ai`, no OCA):
  - `manifest-required-author`
  - `missing-readme`
  - `manifest-author-string`
  - `manifest-maintainers-list`

### Activación (ya hecha en este entorno)

```bash
uv pip install pre-commit
pre-commit install   # instala el hook en .git/hooks/pre-commit
```

### Uso en el día-a-día

```bash
# Sobre staged (lo que el hook hace al commitear)
pre-commit run

# Sobre archivos específicos
pre-commit run --files src/dev/focuz-ai/mi_modulo/models/mi_modelo.py

# Sobre todo (NO recomendado en primera pasada — generaría diff masivo)
pre-commit run --all-files

# Desactivar el hook puntualmente para un commit
git commit --no-verify -m "WIP"
```

> **Primera pasada:** no corras `--all-files` de golpe sobre código existente. Los hooks de auto-fix (Ruff format, trailing-whitespace) reformatearían toda la base. Mejor estrategia: dejar que el hook actúe solo sobre archivos modificados, e ir limpiando módulo por módulo cuando los toques.

### Saltar reglas puntuales

Si una regla genera ruido en un archivo específico:

```python
# pylint: disable=manifest-deprecated-key
```

O desactivarla globalmente agregando `--disable=<msg-id>` en `.pre-commit-config.yaml`.

---

## 10. Hot reload de Python

Asegúrate de que en `config/<cliente>/dev.conf`:

```ini
max_cron_threads = 0   ; obligatorio con --dev=reload
proxy_mode = False     ; evita ruido de X-Forwarded-* si no usas nginx local
```

Y arranca con:

```bash
python odoo/odoo-bin -c config/l10n-pe/dev.conf --dev=xml,reload,qweb
```

`reload` reinicia el servidor cuando guardas un `.py`. Combinado con `xml,qweb` cubre vistas y reportes.

---

## Checklist resumido

| # | Optimización | Ganancia | Aplicado |
|---|--------------|----------|----------|
| 1 | Postgres modo dev (`fsync=off`, etc.) | 5-10× DB-bound | ✅ |
| 2 | `uv` en lugar de `pip` | 10-100× installs | ✅ |
| 3 | Templates de DB (`tpl_l10n_pe`) | minutos → segundos por DB | ✅ creado y probado (clone en 1s) |
| 4 | `--dev=xml,reload,qweb` (no `all`) | menos recompilación de assets | ✅ aplicado en `.vscode/launch.json` |
| 5 | VSCode `files.watcherExclude` | menos CPU del file watcher | ✅ aplicado en `.vscode/settings.json` |
| 6 | Git `fsmonitor` + `untrackedCache` | `git status` instantáneo (~100ms) | ✅ aplicado en `odoo/`, `enterprise/`, `design-themes/` |
| 7 | Filestore: cleanup huérfanos + tmpfs/per-client docs | 129 GB recuperables identificados | ✅ script + doc (no `--apply` aún) |
| 8 | `pytest-odoo` | mejor DX en tests | ✅ instalado (con `pip install -e ./odoo`) |
| 9 | `pylint-odoo` en pre-commit | atrapa antipatrones Odoo | ✅ instalado y configurado (sin `--all-files` aún) |
| 10 | Hot reload (`--dev=reload`) | sin reiniciar servidor | ✅ cubierto por #4 |
