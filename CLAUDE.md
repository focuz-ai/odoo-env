# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is an Odoo 17.0 development environment with Visual Studio Code integration. The project follows a multi-repository structure with Community, Enterprise, and Theme modules organized in separate directories.

## Development Commands

### Environment Setup
```bash
# Initial setup (Ubuntu 20.04, 22.04, 24.04)
chmod +x setup_env.sh
./setup_env.sh

# Clone Odoo repositories
chmod +x clone-addons.sh
./clone-addons.sh

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip3 install --upgrade pip setuptools wheel --no-cache-dir
pip3 install pydevd-odoo nox
pip3 install -r odoo/requirements.txt --no-cache-dir
pip3 install -r requirements.txt --no-cache-dir
```

### Running Odoo
```bash
# Development mode with all debug features
python odoo/odoo-bin -c config/odoo.conf --dev=all

# Specific development modes
# --dev=assets (CSS/JS debugging)
# --dev=qweb (QWeb templates)
# --dev=xml (XML views)
# --dev=pdb (Python debugger on errors)
```

### Common Development Tasks
```bash
# Create new module scaffold
python odoo/odoo-bin scaffold module_name src/addons/

# Access Odoo shell
python odoo/odoo-bin shell -d database_name -c config/odoo.conf

# IPython shell (enhanced REPL)
python odoo/odoo-bin shell -c config/odoo.conf -d database_name --shell-interface ipython

# Run tests (requires test_enable=True in config)
python odoo/odoo-bin -c config/odoo.conf -d database_name --test-enable --test-tags=module_name
```

## Architecture

### Directory Structure
- **odoo/**: Core Odoo Community source code (git submodule)
- **enterprise/**: Odoo Enterprise modules (requires credentials)
- **themes/**: Official Odoo themes
- **vendor/**: Third-party modules (populated by clone-addons.sh)
- **src/**: Custom development modules
- **config/**: Odoo configuration files
  - `odoo.conf`: Main configuration (copy from odoo.conf.example)
- **venv/**: Python virtual environment

### Key Configuration Files
- **.env**: Environment variables for repository cloning and versions
  - `ODOO_TAG`: Odoo version (e.g., 17.0)
  - `GITHUB_USER/GITHUB_ACCESS_TOKEN`: For private repos
- **config/odoo.conf**: Odoo server configuration
  - Database connection settings
  - Addon paths (must include all module directories)
  - Development options
- **.vscode/launch.json**: VSCode debugging configurations
  - DEV: Main development configuration
  - Shell: Interactive shell configuration

### Module Development
1. Modules follow standard Odoo structure with `__manifest__.py`
2. Custom modules go in `src/` directory
3. Third-party modules are managed via `third-party-addons.txt`
4. Module paths must be included in `addons_path` in odoo.conf

### Testing Strategy
- Enable testing with `--test-enable` flag
- Use `--test-tags` to run specific module tests
- Test configuration in odoo.conf:
  - `test_enable = False` (default)
  - `test_tags = None`

### Important Notes
- PostgreSQL client is required (installed by setup_env.sh)
- Default PostgreSQL port in config: 5454
- Virtual environment activation is required before running Odoo
- Watch for inotify limits on Linux (see README for fix)
- Development server runs on port 8079 by default