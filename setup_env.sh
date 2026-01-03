#!/bin/bash

set -euo pipefail

# Colores (usando $'...' para interpretar secuencias de escape)
GREEN=$'\e[32m'
YELLOW=$'\e[33m'
RED=$'\e[31m'
BLUE=$'\e[34m'
NC=$'\e[0m'

# Variables globales
DISTRO=""
DISTRO_VERSION=""
CODENAME=""
PYTHON_VERSION="3.13"
PYTHON_MIN_VERSION=10
PYTHON_MAX_VERSION=14

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

show_help() {
    cat << EOF
${BLUE}Odoo Development Environment Setup${NC}

Uso: $0 [opciones]

Opciones:
  -p, --python VERSION    Versión de Python a instalar (3.10 - 3.14)
                          Por defecto: 3.13
  -h, --help              Mostrar esta ayuda

Ejemplos:
  $0                      Instalar con Python 3.13 (por defecto)
  $0 -p 3.12              Instalar con Python 3.12
  $0 --python 3.11        Instalar con Python 3.11

Distribuciones soportadas:
  - Ubuntu 22.04, 24.04
  - Debian 11, 12
  - Linux Mint, Pop!_OS (basados en Ubuntu)

EOF
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--python)
                if [[ -z "${2:-}" ]]; then
                    log_error "La opción $1 requiere un argumento."
                    exit 1
                fi
                PYTHON_VERSION="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                ;;
            *)
                log_error "Opción desconocida: $1"
                log_info "Usa '$0 --help' para ver las opciones disponibles."
                exit 1
                ;;
        esac
    done
}

validate_python_version() {
    local version="$1"
    local minor

    if [[ ! "$version" =~ ^3\.([0-9]+)$ ]]; then
        log_error "Formato de versión inválido: $version"
        log_error "Formato esperado: 3.X (ejemplo: 3.12)"
        exit 1
    fi

    minor="${BASH_REMATCH[1]}"

    if [[ "$minor" -lt "$PYTHON_MIN_VERSION" || "$minor" -gt "$PYTHON_MAX_VERSION" ]]; then
        log_error "Versión de Python no soportada: $version"
        log_error "Versiones permitidas: 3.${PYTHON_MIN_VERSION} - 3.${PYTHON_MAX_VERSION}"
        exit 1
    fi

    log_info "Versión de Python seleccionada: $version"
}

# Dependencias base comunes (sin python3 genérico)
BASE_DEPS=(
    git build-essential wget curl gnupg lsb-release software-properties-common
    libsasl2-dev libldap2-dev libssl-dev libpq-dev
    libxml2-dev libxslt1-dev libevent-dev libffi-dev
    libjpeg-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev
    liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev
    node-less
)

# Dependencias específicas por versión
DEPS_UBUNTU_22=("libtiff5-dev")
DEPS_UBUNTU_24=("libtiff-dev")
DEPS_DEBIAN_11=("libtiff5-dev")
DEPS_DEBIAN_12=("libtiff-dev")

detect_distro() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "No se puede detectar la distribución. Archivo /etc/os-release no encontrado."
        exit 1
    fi

    source /etc/os-release

    DISTRO="${ID,,}"
    DISTRO_VERSION="${VERSION_ID}"
    CODENAME="${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || echo 'unknown')}"

    log_info "Distribución detectada: ${DISTRO^} ${DISTRO_VERSION} (${CODENAME})"
}

check_compatibility() {
    local supported=false

    case "$DISTRO" in
        ubuntu)
            case "$DISTRO_VERSION" in
                22.04|24.04) supported=true ;;
                23.*|22.*|24.*)
                    log_warn "Ubuntu ${DISTRO_VERSION} no está oficialmente soportado, pero se intentará continuar."
                    supported=true
                    ;;
            esac
            ;;
        debian)
            case "$DISTRO_VERSION" in
                11|12) supported=true ;;
                *)
                    if [[ "${DISTRO_VERSION%%.*}" -ge 11 ]]; then
                        log_warn "Debian ${DISTRO_VERSION} no está oficialmente soportado, pero se intentará continuar."
                        supported=true
                    fi
                    ;;
            esac
            ;;
        linuxmint|pop)
            log_warn "${DISTRO^} detectado. Usando configuración de Ubuntu como base."
            DISTRO="ubuntu"
            supported=true
            ;;
    esac

    if [[ "$supported" != true ]]; then
        log_error "Distribución no soportada: ${DISTRO^} ${DISTRO_VERSION}"
        log_error "Distribuciones soportadas: Ubuntu 22.04/24.04, Debian 11/12"
        exit 1
    fi
}

get_distro_deps() {
    local deps=("${BASE_DEPS[@]}")

    case "$DISTRO" in
        ubuntu)
            case "$DISTRO_VERSION" in
                22.04|22.*|23.*)
                    deps+=("${DEPS_UBUNTU_22[@]}")
                    ;;
                24.04|24.*)
                    deps+=("${DEPS_UBUNTU_24[@]}")
                    ;;
                *)
                    deps+=("${DEPS_UBUNTU_24[@]}")
                    ;;
            esac
            ;;
        debian)
            case "$DISTRO_VERSION" in
                11)
                    deps+=("${DEPS_DEBIAN_11[@]}")
                    ;;
                12|*)
                    deps+=("${DEPS_DEBIAN_12[@]}")
                    ;;
            esac
            ;;
    esac

    echo "${deps[@]}"
}

install_python() {
    local py_cmd="python${PYTHON_VERSION}"
    local py_minor="${PYTHON_VERSION#3.}"

    if command -v "$py_cmd" &>/dev/null; then
        log_info "Python ${PYTHON_VERSION} ya instalado ($($py_cmd --version)), omitiendo..."
        return 0
    fi

    log_info "Instalando Python ${PYTHON_VERSION}..."

    case "$DISTRO" in
        ubuntu)
            install_python_ubuntu
            ;;
        debian)
            install_python_debian
            ;;
    esac

    # Instalar pip para la versión específica
    install_pip
}

install_python_ubuntu() {
    local py_cmd="python${PYTHON_VERSION}"

    # Agregar PPA deadsnakes si no existe
    if ! grep -q "deadsnakes" /etc/apt/sources.list.d/*.list 2>/dev/null; then
        log_info "Agregando PPA deadsnakes..."
        sudo add-apt-repository -y ppa:deadsnakes/ppa
        sudo apt-get update -qq
    fi

    # Instalar Python y paquetes relacionados
    sudo apt-get install -y --no-install-recommends \
        "${py_cmd}" \
        "${py_cmd}-dev" \
        "${py_cmd}-venv" \
        "${py_cmd}-distutils" 2>/dev/null || \
    sudo apt-get install -y --no-install-recommends \
        "${py_cmd}" \
        "${py_cmd}-dev" \
        "${py_cmd}-venv"
}

install_python_debian() {
    local py_cmd="python${PYTHON_VERSION}"
    local py_minor="${PYTHON_VERSION#3.}"

    # Intentar instalar desde repositorios oficiales primero
    if sudo apt-get install -y --no-install-recommends \
        "${py_cmd}" \
        "${py_cmd}-dev" \
        "${py_cmd}-venv" 2>/dev/null; then
        return 0
    fi

    log_warn "Python ${PYTHON_VERSION} no disponible en repositorios. Compilando desde source..."
    install_python_from_source
}

install_python_from_source() {
    local py_version_full="${PYTHON_VERSION}.0"
    local src_dir="/tmp/python-build"
    local install_prefix="/usr/local"

    # Dependencias para compilar Python
    sudo apt-get install -y --no-install-recommends \
        build-essential zlib1g-dev libncurses5-dev libgdbm-dev \
        libnss3-dev libreadline-dev libffi-dev libsqlite3-dev \
        libbz2-dev liblzma-dev

    mkdir -p "$src_dir"
    cd "$src_dir"

    log_info "Descargando Python ${PYTHON_VERSION}..."
    wget -q "https://www.python.org/ftp/python/${py_version_full}/Python-${py_version_full}.tgz"
    tar -xzf "Python-${py_version_full}.tgz"
    cd "Python-${py_version_full}"

    log_info "Compilando Python ${PYTHON_VERSION} (esto puede tardar varios minutos)..."
    ./configure --enable-optimizations --prefix="$install_prefix" 2>/dev/null
    make -j"$(nproc)"
    sudo make altinstall

    # Limpiar
    cd /
    rm -rf "$src_dir"
}

install_pip() {
    local py_cmd="python${PYTHON_VERSION}"

    if "$py_cmd" -m pip --version &>/dev/null; then
        log_info "pip ya instalado para Python ${PYTHON_VERSION}"
        return 0
    fi

    log_info "Instalando pip para Python ${PYTHON_VERSION}..."
    curl -sS https://bootstrap.pypa.io/get-pip.py | sudo "$py_cmd"
}

install_odoo_deps() {
    log_info "Instalando dependencias de Odoo para ${DISTRO^} ${DISTRO_VERSION}..."

    local deps
    read -ra deps <<< "$(get_distro_deps)"

    sudo apt-get install -y --no-install-recommends "${deps[@]}"
}

install_postgresql_client() {
    local pgdg_list="/etc/apt/sources.list.d/pgdg.list"
    local pgdg_key="/usr/share/keyrings/postgresql.gpg"

    if command -v psql &>/dev/null; then
        log_info "PostgreSQL client ya instalado ($(psql --version)), omitiendo..."
        return 0
    fi

    log_info "Instalando PostgreSQL client..."

    if [[ ! -f "$pgdg_key" ]]; then
        wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
            sudo gpg --dearmor -o "$pgdg_key"
    fi

    echo "deb [signed-by=$pgdg_key] http://apt.postgresql.org/pub/repos/apt/ ${CODENAME}-pgdg main" | \
        sudo tee "$pgdg_list" >/dev/null

    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends postgresql-client
}

show_summary() {
    local py_cmd="python${PYTHON_VERSION}"

    log_info "========================================"
    log_info "Resumen de instalación:"
    log_info "  Distribución: ${DISTRO^} ${DISTRO_VERSION}"
    log_info "  Codename: ${CODENAME}"
    log_info "  Python: $($py_cmd --version 2>/dev/null || echo 'No instalado')"
    log_info "  pip: $($py_cmd -m pip --version 2>/dev/null || echo 'No instalado')"
    log_info "  PostgreSQL: $(psql --version 2>/dev/null || echo 'No instalado')"
    log_info "========================================"
    log_info ""
    log_info "Próximos pasos:"
    log_info "  1. Clonar Odoo: ./clone-addons.sh"
    log_info "  2. Crear venv:  $py_cmd -m venv .venv"
    log_info "  3. Activar:     source .venv/bin/activate"
    log_info "  4. Instalar:    pip install -r odoo/requirements.txt"
    log_info ""
    log_info "Entorno configurado correctamente!"
}

main() {
    parse_args "$@"
    validate_python_version "$PYTHON_VERSION"

    log_info "Iniciando configuración del entorno de desarrollo Odoo..."

    detect_distro
    check_compatibility

    log_info "Actualizando sistema..."
    sudo apt-get update -qq && sudo apt-get upgrade -y

    install_odoo_deps
    install_python
    install_postgresql_client

    show_summary
}

main "$@"
