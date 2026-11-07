#!/bin/bash

# =============================================================================
# clone-addons.sh - Clone Odoo repositories, update them and optionally sync with upstream
# =============================================================================

SCRIPT_NAME=$(basename "$0")
CONFIG_FILE="clone-addons.txt"
SYNC_ENABLED=false
UPDATE_ENABLED=false
SLIM_ENABLED=false

# Show help message
show_help() {
    cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS]

Clone Odoo repositories configured in ${CONFIG_FILE}.
Without options, missing repositories are cloned and existing ones are left untouched.

OPTIONS:
    -u, --update    Also update already-cloned repositories to the tip of their branch.
                    Shallow repos fetch only the new snapshot (--depth 1), so their local
                    history becomes a single commit. Repos with local commits or
                    uncommitted changes are skipped (listed at the end).
    --slim          New clones download only Spanish translations (i18n/es*.po) using a
                    partial clone + sparse-checkout: ~42% less data, fetched in small
                    resumable batches. Recommended on slow connections. Requires git >= 2.31.
                    Restore all languages later with: git -C <repo> sparse-checkout disable
    -s, --sync      Sync focuz-ai forks with upstream Odoo repositories
                    (fetches latest changes, merges, and pushes to fork; needs full clones)
    -h, --help      Show this help message and exit

EXAMPLES:
    ${SCRIPT_NAME}              Clone missing repositories only
    ${SCRIPT_NAME} --update     Clone missing repositories and update existing ones
    ${SCRIPT_NAME} --slim       Clone missing repositories with Spanish translations only
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
        -u|--update)
            UPDATE_ENABLED=true
            shift
            ;;
        --slim)
            SLIM_ENABLED=true
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

# Before sourcing: with CRLF, bash would print "$'\r': command not found" first.
if grep -q $'\r' .env "$CONFIG_FILE" 2>/dev/null; then
    echo -e "\e[31m❌ CRLF line endings in .env or ${CONFIG_FILE}; run: sed -i 's/\\\\r\$//' .env ${CONFIG_FILE}\e[0m"
    exit 1
fi

source .env
set -e

# Defaults documented in --help; no trailing slash (used as ODOO_UPSTREAM keys and "<dir>.partial").
ENTERPRISE_ADDONS=${ENTERPRISE_ADDONS:-enterprise}
ENTERPRISE_ADDONS=${ENTERPRISE_ADDONS%/}
THEMES_ADDONS=${THEMES_ADDONS:-design-themes}
THEMES_ADDONS=${THEMES_ADDONS%/}
THIRD_PARTY_ADDONS=${THIRD_PARTY_ADDONS:-vendor}

# A broken <dir>/.git or a half-made .partial must not resolve to the o19-env repo itself
# (git walks up the parents and we would reset/fetch it).
export GIT_CEILING_DIRECTORIES=$PWD
# Bad credentials fail fast instead of prompting inside retry().
export GIT_TERMINAL_PROMPT=${GIT_TERMINAL_PROMPT:-0}
# Abort only DEAD connections: servers send a keepalive every 5 s, so 0 B/s for 60 s is not a slow
# download. A higher threshold would kill live slow downloads (and the retry starts from zero).
export GIT_HTTP_LOW_SPEED_LIMIT=${GIT_HTTP_LOW_SPEED_LIMIT:-1}
export GIT_HTTP_LOW_SPEED_TIME=${GIT_HTTP_LOW_SPEED_TIME:-60}
# HTTP/1.1 avoids "curl 92 HTTP/2 stream was not closed cleanly" on flaky networks; git makes few large
# requests and gains nothing from HTTP/2. Reaches every git call, including internal lazy fetches.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=http.version GIT_CONFIG_VALUE_0=HTTP/1.1

LOG_FILE=$(pwd)/clone.log

SKIPPED=()
trap 'if [ ${#SKIPPED[@]} -gt 0 ]; then echo -e "\e[33m⚠️  Skipped:\e[0m"; printf "   - %s\n" "${SKIPPED[@]}"; fi' EXIT

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

# Función para escribir en el log (nunca la URL: puede llevar el token)
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Run a command up to 5 times, waiting 15/30/45/60 s between attempts.
retry() {
    local n
    for n in 1 2 3 4 5; do
        "$@" && return 0
        if [ "$n" -lt 5 ]; then
            echo -e "\e[33m⚠️  Attempt $n failed; retrying in $((n * 15))s...\e[0m" >&2
            sleep $((n * 15))
        fi
    done
    return 1
}

is_clone() { [ -d "$1/.git" ] && git -C "$1" rev-parse -q --verify HEAD >/dev/null 2>&1; }

skip() {
    SKIPPED+=("$1: $2")
    echo -e "\e[33m⚠️  Skipping $1: $2\e[0m"
}

# Repository URL with the credentials its type needs
auth_url() {
    local repo_type=$1 repo_url=$2
    case $repo_type in
        private) echo "https://${GITHUB_USER}:${GITHUB_ACCESS_TOKEN}@${repo_url#https://}" ;;
        enterprise) echo "https://${ENTERPRISE_USER}:${ENTERPRISE_ACCESS_TOKEN}@${repo_url#https://}" ;;
        *) echo "$repo_url" ;;
    esac
}

# One clone attempt: <url> <dir> [branch]. Runs inside retry(), where set -e does NOT apply:
# every step must be chained.
clone_once() {
    local -a opts=(--depth 1 --single-branch --no-tags ${3:+--branch "$3"})
    if [ "$SLIM_ENABLED" = true ]; then
        opts+=(--filter=blob:none --no-checkout)
    fi
    rm -rf "$2" && git clone "${opts[@]}" "$1" "$2"
}

# Same command git runs internally for lazy fetches (promisor-remote.c), with explicit OIDs:
# <dir> <remote> <oid>...
fetch_blobs() {
    local d=$1 r=$2
    shift 2
    printf '%s\n' "$@" | git -C "$d" -c fetch.negotiationAlgorithm=noop fetch "$r" \
        --no-tags --no-write-fetch-head --recurse-submodules=no --filter=blob:none --stdin
}

# Download the missing blobs of the sparse set in batches of 2000 (~7 MB), so a dropped connection
# only loses the current batch: <dir> <remote> <rev>. Pure optimization: whatever is still missing
# is fetched by the following reset anyway.
# ponytail: Spanish only; the awk filter mirrors the patterns written in clone_repo (change both).
slim_prefetch() {
    local d=$1 r=$2 i end
    local -a oids
    mapfile -t oids < <(comm -12 \
        <(git -C "$d" -c core.quotePath=false ls-tree -r "$3" | awk -F'\t' '$1 ~ / blob / &&
            ($2 !~ /(^|\/)i18n\/[^\/]*\.po$/ || $2 ~ /(^|\/)i18n\/es[^\/]*\.po$/) {split($1, a, " "); print a[3]}' | sort -u) \
        <(git -C "$d" rev-list --objects --missing=print "$3" | sed -n 's/^?//p' | sort -u))
    for ((i = 0; i < ${#oids[@]}; i += 2000)); do
        end=$((i + 2000 < ${#oids[@]} ? i + 2000 : ${#oids[@]}))
        echo -e "\e[36m   📦 ${d}: blobs $((i + 1))-${end} / ${#oids[@]}\e[0m"
        retry fetch_blobs "$d" "$r" "${oids[@]:i:2000}" || return 1
    done
}

# Clone into <dir>.partial and rename at the end, so an interrupted clone never looks "already cloned".
clone_repo() {
    local dir=$1 url=$2 tmp="$1.partial" branch=$ODOO_TAG refs slim=$SLIM_ENABLED
    # Resume a --slim .partial of the same URL even when re-run without --slim (otherwise we would throw
    # away what was already downloaded, precisely for whoever has a bad connection).
    if is_clone "$tmp" && [ "$(git -C "$tmp" config remote.origin.url)" = "$url" ] &&
        [ "$(git -C "$tmp" config remote.origin.promisor)" = true ]; then
        echo -e "\e[36m⏯️  Resuming ${tmp}\e[0m"
        slim=true
    else
        [ -n "$ODOO_TAG" ] || { echo -e "\e[31m❌ ODOO_TAG is empty in .env\e[0m"; return 1; }
        # Empty output = branch/tag does not exist; error = network (retried, never falls back to master).
        refs=$(retry git ls-remote "$url" "refs/heads/$ODOO_TAG" "refs/tags/$ODOO_TAG") || return 1
        if [ -z "$refs" ]; then
            # odoo/enterprise/themes: the default branch is never valid, except with --sync (which then
            # creates the branch from upstream).
            if [ -n "${ODOO_UPSTREAM[$dir]:-}" ] && [ "$SYNC_ENABLED" != true ]; then
                echo -e "\e[31m❌ ${ODOO_TAG} not found in the remote of ${dir}\e[0m"
                return 1
            fi
            echo -e "\e[33m⚠️  Branch ${ODOO_TAG} not found, using default branch...\e[0m"
            branch=""
        fi
        retry clone_once "$url" "$tmp" "$branch" || return 1
    fi
    if [ "$slim" = true ]; then
        # Idempotent, so a resumed .partial gets it too. Non-cone patterns written by hand: git 2.34
        # (Ubuntu 22.04) lacks `sparse-checkout set --no-cone`. log.showRoot=false: otherwise
        # `git show`/`log -p` of the (shallow) root commit diffs against the empty tree and downloads
        # every excluded .po. reset --hard (not read-tree): tolerates half-written files of a prior attempt.
        git -C "$tmp" config core.sparseCheckout true &&
            git -C "$tmp" config core.sparseCheckoutCone false &&
            git -C "$tmp" config log.showRoot false &&
            mkdir -p "$tmp/.git/info" &&
            printf '%s\n' '/*' '!**/i18n/*.po' '**/i18n/es*.po' > "$tmp/.git/info/sparse-checkout" &&
            slim_prefetch "$tmp" origin HEAD &&
            git -C "$tmp" reset -q --hard HEAD || return 1
    fi
    mv "$tmp" "$dir"
}

# Bring an existing clone to the tip of its upstream. Called from `||`: set -e does not apply here.
update_repo() {
    local dir=$1 b remote merge track old
    b=$(git -C "$dir" symbolic-ref --short -q HEAD) || { skip "$dir" "detached HEAD"; return 0; }
    remote=$(git -C "$dir" config "branch.$b.remote") && merge=$(git -C "$dir" config "branch.$b.merge") &&
        track=$(git -C "$dir" rev-parse --symbolic-full-name '@{upstream}' 2>/dev/null) ||
        { skip "$dir" "branch $b has no upstream"; return 0; }
    [ "$(git -C "$dir" rev-list --count "$track..HEAD")" = 0 ] ||
        { skip "$dir" "local commits not in $track"; return 0; }
    git -C "$dir" update-index -q --refresh
    git -C "$dir" diff-index --quiet HEAD -- ||
        { skip "$dir" "uncommitted changes (commit or stash them, then re-run)"; return 0; }
    old=$(git -C "$dir" rev-parse HEAD)
    echo -e "\e[36m🔄 Updating ${dir}...\e[0m"
    if [ "$(git -C "$dir" rev-parse --is-shallow-repository)" = true ]; then
        # depth 1: only what differs from the local snapshot (never more than a pull); --ff-only cannot
        # work on shallow repos (the new commit has no local ancestors). --refmap= keeps the upstream ref
        # still until the reset is done: if interrupted in between, the upstream never points to a commit
        # without local ancestors (which would report "local commits" forever).
        retry git -C "$dir" fetch --depth 1 --no-tags --refmap= "$remote" "$merge" || return 1
        if [ "$(git -C "$dir" config "remote.$remote.promisor")" = true ]; then
            slim_prefetch "$dir" "$remote" FETCH_HEAD || return 1   # --slim repo: new blobs in batches
        fi
        git -C "$dir" reset -q --keep FETCH_HEAD ||
            { skip "$dir" "reset failed (untracked files in the way? see git error above)"; return 0; }
        git -C "$dir" update-ref "$track" HEAD
    else
        # Full clone (e.g. after --sync): keep it full.
        retry git -C "$dir" fetch --no-tags "$remote" "$merge" || return 1
        git -C "$dir" merge -q --ff-only FETCH_HEAD || { skip "$dir" "cannot fast-forward"; return 0; }
    fi
    if [ "$old" = "$(git -C "$dir" rev-parse HEAD)" ]; then
        echo -e "\e[32m${dir} already up to date 🆗\e[0m"
    else
        echo -e "\e[32m${dir} updated → $(git -C "$dir" log -1 --format='%h %s') 🆗\e[0m"
    fi
}

# Clone <dir> if missing; with --update, update it; with --sync, sync it.
ensure_repo() {
    local dir=$1 url=$2
    if is_clone "$dir"; then
        if [ "$UPDATE_ENABLED" = true ]; then
            update_repo "$dir" || {
                log "Error updating ${dir}"
                echo -e "\e[31m❌ Error updating ${dir}\e[0m"
                exit 1
            }
        else
            echo -e "\e[32mRepository ${dir} already cloned; skipping download 🆗\e[0m"
        fi
    elif [ -e "$dir" ] || [ -L "$dir" ]; then   # -L: dangling symlink (e.g. unmounted drive)
        echo -e "\e[31mRepository ${dir} exists but has no completed clone; inspect it before retrying.\e[0m"
        exit 1
    else
        clone_repo "$dir" "$url" || {
            log "Error cloning ${dir}"
            echo -e "\e[31m❌ Error cloning ${dir} (re-run to retry)\e[0m"
            exit 1
        }
        echo -e "\e[32mClone repository ${dir} 🆗\e[0m"
    fi
    if [ "$SYNC_ENABLED" = true ]; then
        if [ "$(git -C "$dir" config remote.origin.promisor)" = true ]; then
            skip "$dir" "--slim clone; --sync needs a full clone"
        else
            sync_fork_with_upstream "$dir"
        fi
    fi
}

# Function to clone and copy modules based on conditions
clone_and_copy_modules() {
    local repo_type=$1
    local repo_url=$2
    local check=$3
    local dir

    shift 2
    local modules_conditions=("$@")

    case $repo_type in
        enterprise) dir=$ENTERPRISE_ADDONS ;;
        themes) dir=$THEMES_ADDONS ;;
        *) dir=$(basename -s .git "$repo_url") ;;
    esac

    if [[ $repo_type == "enterprise" ]]; then
        [[ $check == true ]] || return 0
        # Updating an existing clone uses the URL stored in its .git/config: no token needed.
        if { [ -n "$ENTERPRISE_USER" ] && [ -n "$ENTERPRISE_ACCESS_TOKEN" ]; } || is_clone "$dir"; then
            ensure_repo "$dir" "$(auth_url "$repo_type" "$repo_url")"
        else
            echo -e "\e[33m⚠️  Skipping ${dir}: no ENTERPRISE_USER/ENTERPRISE_ACCESS_TOKEN in .env\e[0m"
        fi
        return 0
    fi

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
    [[ $should_clone == true ]] || return 0

    ensure_repo "$dir" "$(auth_url "$repo_type" "$repo_url")"

    # Copy the modules whose condition is true (never overwrite: vendor copies may carry local patches)
    if [[ ${#modules_conditions[@]} -gt 1 ]]; then
        for (( i=0; i<${#modules_conditions[@]}; i+=2 )); do
            local module=${modules_conditions[i]}
            local condition=${modules_conditions[i+1]}
            if [[ $condition == true ]]; then
                if [ -e "${THIRD_PARTY_ADDONS}/${module}" ]; then
                    echo -e "\e[33m⚠️  ${THIRD_PARTY_ADDONS}/${module} exists; not overwritten (delete it to refresh)\e[0m"
                else
                    echo -e "\e[32mCopying ${module} from ${dir} into ${THIRD_PARTY_ADDONS}\e[0m"
                    cp -r "${dir}/${module}" "${THIRD_PARTY_ADDONS}/${module}"
                fi
            fi
        done
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

mkdir -p "${THIRD_PARTY_ADDONS}"

# Read the configuration file and process each line
while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    echo "=================================================="
    echo $(expand_env_vars "$line")
    echo "=================================================="
    clone_and_copy_modules $(expand_env_vars "$line")
done < "$CONFIG_FILE"
