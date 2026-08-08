# AGENTS.md

General environment, dependency, IDE and coding guidance lives in `CLAUDE.md` and `docs/`.
Read those first for standard commands; this file only adds Cursor Cloud specifics.

## Cursor Cloud specific instructions

This repo is a **scaffolding/harness** for an Odoo 19 dev environment — the runnable
Odoo source is **not** committed and is cloned into the workspace at setup time.

### What is already provisioned in the VM snapshot (do not redo)

- `odoo/` (Odoo 19 Community) and `design-themes/` are cloned (shallow, branch `19.0`);
  both are git-ignored and persist in the VM snapshot. `odoo-bin` is at `odoo/odoo-bin`;
  the core addons live in `odoo/odoo/addons` and `odoo/addons`.
- `.venv/` is a Python 3.12 venv with `odoo/requirements.txt` + `requirements.txt` installed
  (managed with `uv`). The update script refreshes these on each session.
- System packages (build libs, `wkhtmltopdf`, PostgreSQL 16 server+client) are installed.
- Active dev config: `config/l10n-pe/dev.conf` (git-ignored, created for cloud). It points
  `addons_path` at the absolute `/workspace/...` paths and uses `data_dir = /workspace/.local/share/Odoo`.

### Per-session startup (NOT in the update script)

- **Start PostgreSQL** — the server is not auto-started on boot:
  `sudo pg_ctlcluster 16 main start`
  DB role `odoo` / password `odoo` on `127.0.0.1:5432`. (Note: `CLAUDE.md`/`README.md` mention
  port 5435, but the example configs and this cloud setup use **5432**.)
- **Run Odoo** (DB `odoo_dev` is pre-initialized with demo data; login `admin` / `admin`):
  `source .venv/bin/activate && python odoo/odoo-bin -c config/l10n-pe/dev.conf -d odoo_dev`
  then open http://localhost:8069 .

### Gotchas

- **Enterprise is NOT cloned.** `clone-addons.txt` points enterprise at the private
  `focuz-ai/odoo-fork-enterprise`, which needs `GITHUB_USER`/`GITHUB_ACCESS_TOKEN` (or
  `ENTERPRISE_USER`/`ENTERPRISE_ACCESS_TOKEN`) in `.env`. Set those, run `./clone-addons.sh`,
  then add `/workspace/enterprise` to `addons_path` in the config to use EE/focuz-ai modules.
- **Tests while the dev server is running:** odoo-bin binds the config's HTTP port even with
  `--stop-after-init`, so pass free ports, e.g.:
  `python odoo/odoo-bin -c config/l10n-pe/dev.conf -d odoo_test -i base --test-enable --test-tags /base:TestSafeEval --http-port=8071 --gevent-port=8072 --stop-after-init`
- **Lint:** `ruff check .` (config in `ruff.toml`; vendored trees excluded). `ruff` is not in
  `requirements.txt` — install on demand (`uv pip install ruff`) or via `pre-commit`.
