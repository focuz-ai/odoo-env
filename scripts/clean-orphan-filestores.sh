#!/usr/bin/env bash
# =============================================================================
# clean-orphan-filestores.sh - Detecta filestores cuya DB ya no existe
#                              en NINGUNA instancia Postgres
# =============================================================================
#
# Uso:
#   ./scripts/clean-orphan-filestores.sh [--apply] [opciones]
#
# Por defecto corre en modo dry-run. Pasa --apply para borrar.
#
# Argumentos:
#   --apply                 Borra los huérfanos (sin este flag solo lista).
#   --data-dir DIR          Filestore (default: ~/.local/share/Odoo/filestore)
#   --instances-glob GLOB   Glob de directorios con .env de instancias Postgres
#                           (default: /mnt/d/Projects/Docker/pg_odoo_*)
#   --instance HOST:PORT:USER:PASS
#                           Agregar una instancia manual; repetible.
#                           Si se usa, sobreescribe --instances-glob.
#
# El script recorre TODAS las instancias Postgres detectadas, une la lista
# de DBs (incluyendo templates), y solo marca como huérfano un filestore
# cuyo nombre no coincida con NINGUNA DB en NINGUNA instancia.
#
# Ejemplos:
#   ./scripts/clean-orphan-filestores.sh                    # dry-run global
#   ./scripts/clean-orphan-filestores.sh --apply            # borrar
#   ./scripts/clean-orphan-filestores.sh \
#       --instance 127.0.0.1:5432:odoo:odoo \
#       --instance 127.0.0.1:5435:odoo:odoo
# =============================================================================
set -euo pipefail

APPLY=false
DATA_DIR="$HOME/.local/share/Odoo/filestore"
INSTANCES_GLOB="/mnt/d/Projects/Docker/pg_odoo_*"
MANUAL_INSTANCES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply) APPLY=true; shift ;;
        --data-dir) DATA_DIR="$2"; shift 2 ;;
        --instances-glob) INSTANCES_GLOB="$2"; shift 2 ;;
        --instance) MANUAL_INSTANCES+=("$2"); shift 2 ;;
        -h|--help) sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Opción desconocida: $1" >&2; exit 1 ;;
    esac
done

if [[ ! -d "$DATA_DIR" ]]; then
    echo -e "\e[31m❌ Filestore no encontrado: $DATA_DIR\e[0m"
    exit 1
fi

# --- Construir lista de instancias Postgres --------------------------------
INSTANCES=()  # cada elemento: "host:port:user:pass"

if [[ ${#MANUAL_INSTANCES[@]} -gt 0 ]]; then
    INSTANCES=("${MANUAL_INSTANCES[@]}")
else
    for dir in $INSTANCES_GLOB; do
        env_file="$dir/.env"
        [[ -f "$env_file" ]] || continue
        port=$(awk -F= '/^DB_PORT/{print $2}' "$env_file" | tr -d ' "'"'")
        user=$(awk -F= '/^DB_USER/{print $2}' "$env_file" | tr -d ' "'"'")
        pass=$(awk -F= '/^DB_PASSWORD/{print $2}' "$env_file" | tr -d ' "'"'")
        [[ -n "$port" && -n "$user" && -n "$pass" ]] || continue
        INSTANCES+=("127.0.0.1:$port:$user:$pass")
    done
fi

if [[ ${#INSTANCES[@]} -eq 0 ]]; then
    echo -e "\e[31m❌ No se detectaron instancias Postgres.\e[0m"
    echo "  Usa --instance HOST:PORT:USER:PASS o --instances-glob /ruta/*"
    exit 1
fi

echo -e "\e[36m▶ Filestore:\e[0m $DATA_DIR"
echo -e "\e[36m▶ Instancias Postgres a verificar:\e[0m"
for inst in "${INSTANCES[@]}"; do
    IFS=: read -r h p _u _p <<< "$inst"
    echo "    - $h:$p"
done
echo

# --- Recolectar DBs de TODAS las instancias --------------------------------
ALL_DBS=""
for inst in "${INSTANCES[@]}"; do
    IFS=: read -r host port user pass <<< "$inst"
    export PGPASSWORD="$pass"
    if ! out=$(psql -h "$host" -p "$port" -U "$user" -d postgres -tAc \
        "SELECT datname FROM pg_database;" 2>&1); then
        echo -e "\e[33m⚠ No se pudo conectar a $host:$port — la salto.\e[0m"
        echo "  $out" | head -1
        continue
    fi
    count=$(echo "$out" | grep -cv '^$' || true)
    echo -e "  \e[32m✓\e[0m $host:$port → $count DBs"
    ALL_DBS+="$out"$'\n'
done
unset PGPASSWORD
echo

# --- Detectar huérfanos -----------------------------------------------------
ORPHANS=()
TOTAL_SIZE=0

while IFS= read -r -d '' dir; do
    name=$(basename "$dir")
    if ! grep -qx "$name" <<< "$ALL_DBS"; then
        size_kb=$(du -sk "$dir" | cut -f1)
        ORPHANS+=("$dir|$size_kb")
        TOTAL_SIZE=$((TOTAL_SIZE + size_kb))
    fi
done < <(find "$DATA_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

if [[ ${#ORPHANS[@]} -eq 0 ]]; then
    echo -e "\e[32m✓ No hay filestores huérfanos.\e[0m"
    exit 0
fi

# --- Mostrar resumen ordenado por tamaño -----------------------------------
echo -e "\e[33m⚠ ${#ORPHANS[@]} filestore(s) huérfano(s) (no presentes en ninguna instancia):\e[0m"
echo
printf "  %-50s  %10s\n" "FILESTORE" "TAMAÑO"
printf "  %-50s  %10s\n" "─────────" "──────"
for entry in "${ORPHANS[@]}"; do
    dir="${entry%|*}"
    size_kb="${entry#*|}"
    size_h=$(numfmt --to=iec --from-unit=1024 "$size_kb")
    printf "  %-50s  %10s\n" "$(basename "$dir")" "$size_h"
done | sort -k2 -h -r

TOTAL_HUMAN=$(numfmt --to=iec --from-unit=1024 "$TOTAL_SIZE")
echo
echo -e "\e[36m▶ Espacio recuperable: ${TOTAL_HUMAN}\e[0m"

if [[ "$APPLY" != "true" ]]; then
    echo
    echo -e "\e[33m(modo dry-run)\e[0m  Para borrar: \e[36m$0 --apply\e[0m"
    exit 0
fi

# --- Borrado real ----------------------------------------------------------
echo
echo -e "\e[31m▶ Borrando ${#ORPHANS[@]} directorios...\e[0m"
for entry in "${ORPHANS[@]}"; do
    dir="${entry%|*}"
    rm -rf "$dir"
    echo -e "  \e[31m✗\e[0m $(basename "$dir")"
done
echo
echo -e "\e[32m✓ ${TOTAL_HUMAN} liberados.\e[0m"
