#!/usr/bin/env bash
# =============================================================================
# db-template-create.sh - Crea un template de Postgres con módulos pre-instalados
# =============================================================================
#
# Uso:
#   ./scripts/db-template-create.sh [TEMPLATE_NAME] [MODULES] [CONFIG]
#
# Argumentos (todos opcionales, con defaults):
#   TEMPLATE_NAME   Nombre del template Postgres        (default: tpl_l10n_pe)
#   MODULES         Lista de módulos separados por coma (default: base,web,l10n_pe)
#   CONFIG          Archivo .conf de Odoo               (default: config/l10n-pe/dev.conf)
#
# Ejemplos:
#   ./scripts/db-template-create.sh
#   ./scripts/db-template-create.sh tpl_l10n_pe_edi base,web,l10n_pe,l10n_pe_edi
#   ./scripts/db-template-create.sh tpl_etl base,web,sale,purchase config/ETL/dev.conf
# =============================================================================
set -euo pipefail

TEMPLATE_NAME="${1:-tpl_l10n_pe}"
MODULES="${2:-base,web,l10n_pe}"
CONFIG="${3:-config/l10n-pe/dev.conf}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Lee credenciales desde el .conf
DB_HOST=$(awk -F'= *' '/^db_host/{print $2}' "$CONFIG" | tr -d ' ')
DB_PORT=$(awk -F'= *' '/^db_port/{print $2}' "$CONFIG" | tr -d ' ')
DB_USER=$(awk -F'= *' '/^db_user/{print $2}' "$CONFIG" | tr -d ' ')
DB_PASS=$(awk -F'= *' '/^db_password/{print $2}' "$CONFIG" | tr -d ' ')

export PGPASSWORD="$DB_PASS"
PSQL="psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -v ON_ERROR_STOP=1"

echo -e "\e[36m▶ Template:\e[0m $TEMPLATE_NAME"
echo -e "\e[36m▶ Módulos:\e[0m  $MODULES"
echo -e "\e[36m▶ Config:\e[0m   $CONFIG"
echo -e "\e[36m▶ DB host:\e[0m  $DB_HOST:$DB_PORT (user=$DB_USER)"
echo

# --- 1. Bajar flag template y matar conexiones existentes -------------------
EXISTS=$($PSQL -tAc "SELECT 1 FROM pg_database WHERE datname='$TEMPLATE_NAME'" || true)
if [[ -n "$EXISTS" ]]; then
    echo -e "\e[33m⚠  Template existente. Recreando...\e[0m"
    $PSQL -c "UPDATE pg_database SET datistemplate=false WHERE datname='$TEMPLATE_NAME';"
    $PSQL -c "ALTER DATABASE \"$TEMPLATE_NAME\" ALLOW_CONNECTIONS = true;"
    $PSQL -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$TEMPLATE_NAME';" >/dev/null
    $PSQL -c "DROP DATABASE \"$TEMPLATE_NAME\";"
fi

# --- 2. Crear DB e instalar módulos -----------------------------------------
$PSQL -c "CREATE DATABASE \"$TEMPLATE_NAME\" OWNER $DB_USER;"
echo -e "\e[36m▶ Instalando $MODULES (puede tardar varios minutos)...\e[0m"
python odoo/odoo-bin -c "$CONFIG" -d "$TEMPLATE_NAME" -i "$MODULES" --stop-after-init --no-http

# --- 3. Marcar como template y bloquear conexiones --------------------------
$PSQL -c "ALTER DATABASE \"$TEMPLATE_NAME\" ALLOW_CONNECTIONS = false;"
$PSQL -c "UPDATE pg_database SET datistemplate=true WHERE datname='$TEMPLATE_NAME';"

echo
echo -e "\e[32m✓ Template '$TEMPLATE_NAME' listo.\e[0m"
echo -e "  Para crear una DB limpia desde el template:"
echo -e "  \e[36m./scripts/db-clone-from-template.sh $TEMPLATE_NAME mi_db_nueva\e[0m"
