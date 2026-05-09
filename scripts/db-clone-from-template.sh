#!/usr/bin/env bash
# =============================================================================
# db-clone-from-template.sh - Clona una DB Postgres desde un template
# =============================================================================
#
# Uso:
#   ./scripts/db-clone-from-template.sh TEMPLATE_NAME NEW_DB_NAME [CONFIG]
#
# Ejemplos:
#   ./scripts/db-clone-from-template.sh tpl_l10n_pe pe_test_$(date +%Y%m%d)
#   ./scripts/db-clone-from-template.sh tpl_l10n_pe demo_001 config/l10n-pe/dev.conf
# =============================================================================
set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Uso: $0 TEMPLATE_NAME NEW_DB_NAME [CONFIG]"
    exit 1
fi

TEMPLATE_NAME="$1"
NEW_DB_NAME="$2"
CONFIG="${3:-config/l10n-pe/dev.conf}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

DB_HOST=$(awk -F'= *' '/^db_host/{print $2}' "$CONFIG" | tr -d ' ')
DB_PORT=$(awk -F'= *' '/^db_port/{print $2}' "$CONFIG" | tr -d ' ')
DB_USER=$(awk -F'= *' '/^db_user/{print $2}' "$CONFIG" | tr -d ' ')
DB_PASS=$(awk -F'= *' '/^db_password/{print $2}' "$CONFIG" | tr -d ' ')

export PGPASSWORD="$DB_PASS"
PSQL="psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -v ON_ERROR_STOP=1"

# Drop new DB if exists
EXISTS=$($PSQL -tAc "SELECT 1 FROM pg_database WHERE datname='$NEW_DB_NAME'" || true)
if [[ -n "$EXISTS" ]]; then
    echo -e "\e[33m⚠  Database '$NEW_DB_NAME' ya existe. Eliminando...\e[0m"
    $PSQL -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$NEW_DB_NAME';" >/dev/null
    $PSQL -c "DROP DATABASE \"$NEW_DB_NAME\";"
fi

# Clone — Postgres requiere ALLOW_CONNECTIONS=true durante el clone
echo -e "\e[36m▶ Clonando '$TEMPLATE_NAME' → '$NEW_DB_NAME'...\e[0m"
START=$(date +%s)
$PSQL -c "ALTER DATABASE \"$TEMPLATE_NAME\" ALLOW_CONNECTIONS = true;"
$PSQL -c "CREATE DATABASE \"$NEW_DB_NAME\" WITH TEMPLATE \"$TEMPLATE_NAME\" OWNER $DB_USER;"
$PSQL -c "ALTER DATABASE \"$TEMPLATE_NAME\" ALLOW_CONNECTIONS = false;"
ELAPSED=$(( $(date +%s) - START ))

echo
echo -e "\e[32m✓ DB '$NEW_DB_NAME' creada en ${ELAPSED}s.\e[0m"
echo -e "  Para arrancar Odoo:"
echo -e "  \e[36mpython odoo/odoo-bin -c $CONFIG -d $NEW_DB_NAME\e[0m"
