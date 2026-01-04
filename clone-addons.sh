#!/bin/bash
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

    echo -e "\e[36m🔄 Syncing ${repo_dir} with upstream Odoo...\e[0m"
    pushd "$repo_dir" > /dev/null

    # Unshallow repository if cloned with --depth 1
    if [ -f .git/shallow ]; then
        echo -e "\e[33m   Fetching full history from origin...\e[0m"
        git fetch --unshallow origin ${ODOO_TAG} 2>/dev/null || git fetch origin ${ODOO_TAG}
    fi

    # Add upstream remote if not exists
    if ! git remote get-url upstream &>/dev/null; then
        echo -e "\e[33m   Adding upstream: ${upstream_url}\e[0m"
        git remote add upstream "$upstream_url"
    fi

    # Fetch upstream branch
    echo -e "\e[36m   Fetching upstream/${ODOO_TAG}...\e[0m"
    git fetch upstream ${ODOO_TAG} || {
        echo -e "\e[31m❌ Error fetching upstream\e[0m"
        popd > /dev/null
        return 1
    }

    # Merge upstream changes into current branch
    echo -e "\e[36m   Merging upstream/${ODOO_TAG}...\e[0m"
    git merge upstream/${ODOO_TAG} -m "chore: sync with upstream odoo/${ODOO_TAG}" --no-edit || {
        echo -e "\e[31m❌ Merge conflict in ${repo_dir}. Resolve manually.\e[0m"
        popd > /dev/null
        return 1
    }

    # Push changes to focuz-ai fork
    echo -e "\e[36m   Pushing to focuz-ai fork (origin/${ODOO_TAG})...\e[0m"
    git push origin ${ODOO_TAG} || {
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
            # Sync fork with upstream Odoo and push to focuz-ai
            sync_fork_with_upstream $ENTERPRISE_ADDONS
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
            $clone_cmd --depth 1 --branch ${ODOO_TAG} --single-branch --no-tags || { log "Error clonando el repositorio ${clone_cmd}"; exit 1; }
            echo -e "\e[32mClone repository ${repo_name} 🆗\e[0m"
            # Sync fork with upstream Odoo and push to focuz-ai
            sync_fork_with_upstream $repo_name
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
done < "third-party-addons.txt"
