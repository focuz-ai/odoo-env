#!/bin/bash

# =============================================================================
# clone-addons.sh - Clone Odoo repositories and optionally sync with upstream
# =============================================================================

SCRIPT_NAME=$(basename "$0")
CONFIG_FILE="clone-addons.txt"
SYNC_ENABLED=false

# Show help message
show_help() {
    cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Clone Odoo repositories configured in ${CONFIG_FILE}.

OPTIONS:
    -s, --sync      Sync focuz-ai forks with upstream Odoo repositories
                    (fetches latest changes, merges, and pushes to fork)
    -h, --help      Show this help message and exit

EXAMPLES:
    ${SCRIPT_NAME}              Clone repositories only
    ${SCRIPT_NAME} --sync       Clone and sync with upstream Odoo

CONFIGURATION:
    Repositories are configured in ${CONFIG_FILE} with the format:
    <type> <repo_url> <condition>

    Types:
        public      - Public repository (no auth required)
        private     - Private repository (requires GITHUB_USER/GITHUB_ACCESS_TOKEN)
        enterprise  - Odoo Enterprise (requires ENTERPRISE_USER/ENTERPRISE_ACCESS_TOKEN)
        themes      - Odoo Themes repository

ENVIRONMENT VARIABLES (.env):
    ODOO_TAG                    - Branch/tag to clone (e.g., 16.0)
    GITHUB_USER                 - GitHub username for private repos
    GITHUB_ACCESS_TOKEN         - GitHub token for private repos
    ENTERPRISE_USER             - GitHub username for Enterprise repo
    ENTERPRISE_ACCESS_TOKEN     - GitHub token for Enterprise repo
    ENTERPRISE_ADDONS           - Local folder for Enterprise (default: enterprise)
    THEMES_ADDONS               - Local folder for Themes (default: design-themes)
    THIRD_PARTY_ADDONS          - Local folder for vendor addons (default: vendor)

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--sync)
            SYNC_ENABLED=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "\e[31m❌ Unknown option: $1\e[0m"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

source .env
set -e

LOG_FILE=$(pwd)/clone.log

# Odoo upstream repositories mapping (local_dir -> upstream_url)
declare -A ODOO_UPSTREAM=(
    ["odoo"]="https://github.com/odoo/odoo.git"
    ["${ENTERPRISE_ADDONS}"]="https://github.com/odoo/enterprise.git"
    ["${THEMES_ADDONS}"]="https://github.com/odoo/design-themes.git"
)

# Function to sync focuz-ai fork with upstream Odoo and push
sync_fork_with_upstream() {
    local repo_dir=$1
    local upstream_url=${ODOO_UPSTREAM[$repo_dir]}

    # Skip if no upstream mapping exists
    if [ -z "$upstream_url" ]; then
        return 0
    fi

    if [ ! -d "$repo_dir" ]; then
        echo -e "\e[31m❌ Directory ${repo_dir} not found\e[0m"
        return 1
    fi

    # Skip sync if no GitHub credentials
    if [ -z "$GITHUB_USER" ] || [ -z "$GITHUB_ACCESS_TOKEN" ]; then
        echo -e "\e[33m⚠️  Skipping sync for ${repo_dir} (no GitHub credentials)\e[0m"
        return 0
    fi

    echo -e "\e[36m🔄 Syncing ${repo_dir} with upstream Odoo...\e[0m"
    pushd "$repo_dir" > /dev/null

    # Configure origin remote with credentials for push (if not already set)
    local origin_url=$(git remote get-url origin)
    if [[ "$origin_url" != *"@github.com"* ]]; then
        local auth_url="https://${GITHUB_USER}:${GITHUB_ACCESS_TOKEN}@${origin_url#https://}"
        git remote set-url origin "$auth_url"
    fi

    # Add upstream remote if not exists (with credentials for private repos like enterprise)
    if ! git remote get-url upstream &>/dev/null; then
        local auth_upstream_url="https://${GITHUB_USER}:${GITHUB_ACCESS_TOKEN}@${upstream_url#https://}"
        echo -e "\e[33m   Adding upstream: ${upstream_url}\e[0m"
        git remote add upstream "$auth_upstream_url"
    fi

    # Check if target branch exists on origin
    local branch_exists_on_origin=true
    if ! git ls-remote --heads origin ${ODOO_TAG} | grep -q ${ODOO_TAG}; then
        branch_exists_on_origin=false
        echo -e "\e[33m   Branch ${ODOO_TAG} not found on origin, will create from upstream\e[0m"
    fi

    # Unshallow repository if cloned with --depth 1
    if [ -f .git/shallow ]; then
        echo -e "\e[33m   Fetching full history...\e[0m"
        if [ "$branch_exists_on_origin" = true ]; then
            git fetch --unshallow origin ${ODOO_TAG} 2>/dev/null || git fetch --unshallow origin 2>/dev/null || true
        else
            git fetch --unshallow origin 2>/dev/null || true
        fi
    fi

    # Fetch upstream branch
    echo -e "\e[36m   Fetching upstream/${ODOO_TAG}...\e[0m"
    git fetch upstream ${ODOO_TAG} || {
        echo -e "\e[31m❌ Error fetching upstream\e[0m"
        popd > /dev/null
        return 1
    }

    # If branch doesn't exist on origin, create it from upstream
    if [ "$branch_exists_on_origin" = false ]; then
        echo -e "\e[36m   Creating branch ${ODOO_TAG} from upstream...\e[0m"
        git checkout -b ${ODOO_TAG} upstream/${ODOO_TAG} || {
            echo -e "\e[31m❌ Error creating branch from upstream\e[0m"
            popd > /dev/null
            return 1
        }
    else
        # Merge upstream changes into current branch
        echo -e "\e[36m   Merging upstream/${ODOO_TAG}...\e[0m"
        git merge upstream/${ODOO_TAG} -m "chore: sync with upstream odoo/${ODOO_TAG}" --no-edit || {
            echo -e "\e[31m❌ Merge conflict in ${repo_dir}. Resolve manually.\e[0m"
            popd > /dev/null
            return 1
        }
    fi

    # Push changes to focuz-ai fork
    echo -e "\e[36m   Pushing to focuz-ai fork (origin/${ODOO_TAG})...\e[0m"
    git push -u origin ${ODOO_TAG} || {
        echo -e "\e[31m❌ Error pushing to focuz-ai. Check permissions.\e[0m"
        popd > /dev/null
        return 1
    }

    echo -e "\e[32m✅ ${repo_dir} synced and pushed to focuz-ai!\e[0m"
    popd > /dev/null
}

# Function to construct the clone command
construct_clone_command() {
    local repo_type=$1
    local repo_url=$2
    case $repo_type in
        private) echo "git clone https://${GITHUB_USER}:${GITHUB_ACCESS_TOKEN}@${repo_url#https://}" ;;
        enterprise) echo "git clone https://${ENTERPRISE_USER}:${ENTERPRISE_ACCESS_TOKEN}@${repo_url#https://} ${ENTERPRISE_ADDONS}" ;;
        themes) echo "git clone $repo_url ${THEMES_ADDONS}" ;;
        public) echo "git clone $repo_url" ;;
    esac
}

# Función para escribir en el log
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Función para enviar mensaje
msg() {
    local color=$1
    local msg=$2
    case $color in
        red) echo "\e[32m ${msg} \e[0m" ;;
        blue) echo "\e[31m ${msg} \e[0m" ;;
        yelow) echo "\e[33m ${msg} \e[0m" ;;
    esac
}
delete_repository(){
    local repo_name=$1
    if [ -d $repo_name ]; then
        echo -e "\e[33mDelete repository: ${repo_name} 🔴\e[0m"
        rm -rf $repo_name || { log "Error eliminando el repositorio ${repo_name}"; exit 1; }
    fi
}

# Function to clone and copy modules based on conditions
clone_and_copy_modules() {
    local repo_type=$1
    local repo_url=$2
    local check=$3
    local clone_cmd=$(construct_clone_command $repo_type $repo_url)
    local repo_name=$(basename -s .git "$repo_url")

    shift 2
    local modules_conditions=("$@")

    # Clone and copy logic for enterprise repository
    if [[ $repo_type == "enterprise" && $check == true ]]; then
        if [ -n "$GITHUB_USER" ] && [ -n "$GITHUB_ACCESS_TOKEN" ]; then
            delete_repository $ENTERPRISE_ADDONS
            $clone_cmd --depth 1 --branch ${ODOO_TAG} --single-branch --no-tags || { log "Error clonando el repositorio ${clone_cmd}"; exit 1; }
            echo -e "\e[32mClone repository ${ENTERPRISE_ADDONS} 🆗\e[0m"
            # Sync fork with upstream Odoo and push to focuz-ai (only if --sync flag is set)
            if [ "$SYNC_ENABLED" = true ]; then
                sync_fork_with_upstream $ENTERPRISE_ADDONS
            fi
        fi
    else
        # Determine if any module has a true condition
        local should_clone=false
        if [[ ${#modules_conditions[@]} -eq 1 ]]; then
            [[ ${modules_conditions[0]} == true ]] && should_clone=true
        else
            for (( i=1; i<${#modules_conditions[@]}; i+=2 )); do
                if [[ ${modules_conditions[i]} == true ]]; then
                    should_clone=true
                    break
                fi
            done
        fi
        # Delete repository
        if [[ $repo_type == "themes" ]]; then
            repo_name=$THEMES_ADDONS   
        fi
        if [[ $should_clone == true && -d "$repo_name" ]]; then
            delete_repository $repo_name
        fi
        # Clone the repo if should_clone is true and it's not already cloned
        if [[ $should_clone == true && ! -d "$repo_name" ]]; then
            if ! $clone_cmd --depth 1 --branch ${ODOO_TAG} --single-branch --no-tags 2>/dev/null; then
                echo -e "\e[33m⚠️  Branch ${ODOO_TAG} not found, trying default branch...\e[0m"
                $clone_cmd --depth 1 --single-branch --no-tags || { log "Error clonando el repositorio ${clone_cmd}"; exit 1; }
            fi
            echo -e "\e[32mClone repository ${repo_name} 🆗\e[0m"
            # Sync fork with upstream Odoo and push to focuz-ai (only if --sync flag is set)
            if [ "$SYNC_ENABLED" = true ]; then
                sync_fork_with_upstream $repo_name
            fi
        fi

        # Copy the modules if the condition is true
        if [[ $should_clone == true ]]; then
            for (( i=0; i<${#modules_conditions[@]}; i+=2 )); do
                local module=${modules_conditions[i]}
                local condition=${modules_conditions[i+1]}
                if [[ $condition == true ]]; then
                    echo -e "\e[32mCopying ${module} from ${repo_name} into ${THIRD_PARTY_ADDONS}"
                    cp -r ${repo_name}/${module} ${THIRD_PARTY_ADDONS}/${module}
                fi
            done
            # rm -rf ${repo_name}
        fi
    fi
}

# Function to manually expand environment variables in a string
expand_env_vars() {
    while IFS=' ' read -r -a words; do
        for word in "${words[@]}"; do
            if [[ $word == \$\{* ]]; then
                # Remove the leading '${' and the trailing '}' from the word
                varname=${word:2:-1}
                # Check if the variable is set and not empty
                if [ -n "${!varname+x}" ]; then
                    echo -n "${!varname} " # Substitute with its value
                else
                    echo -n "false " # Default to false if not set
                fi
            else
                echo -n "$word "
            fi
        done
        echo
    done <<< "$1"
}

mkdir -p ${THIRD_PARTY_ADDONS}

# Read the configuration file and process each line
while IFS= read -r line; do
    # echo "Linea: $line"
    # mkdir -p ${ENTERPRISE_ADDONS}
    mkdir -p ${THIRD_PARTY_ADDONS}
    [[ -z "$line" || "$line" == \#* ]] && continue
    echo "=================================================="
    echo $(expand_env_vars "$line")
    echo "=================================================="
    clone_and_copy_modules $(expand_env_vars "$line")
done < "$CONFIG_FILE"
