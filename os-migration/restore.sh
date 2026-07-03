#!/usr/bin/env bash
#
# restore.sh — idempotent OS restore from the os-migration manifests.
#
# Safe to run repeatedly. Every step is guarded so re-running only does the
# outstanding work:
#   * packages/AUR/flatpaks use `--needed` (or per-item install checks), so
#     already-present items are skipped by the package manager itself.
#   * services are only enabled if not already enabled.
#   * a .restore-state file records completed *interactive* steps so a rerun
#     doesn't re-prompt; delete it (or a single line) to redo a step.
#
# Usage:
#   ./restore.sh            # interactive, asks before each step
#   ./restore.sh --yes      # non-interactive, run every step (for automation)
#
# This script is also invoked (with --yes) by chezmoi's
# run_onchange_after_ hook when the `migrate` flag is set — see that script.

set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$0")")"

STATE=".restore-state"
ASSUME_YES=0
[[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]] && ASSUME_YES=1

touch "$STATE"

log()  { printf '\033[1;34m[restore]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[restore]\033[0m %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

done_step() { grep -qxF "$1" "$STATE"; }
mark_done() { done_step "$1" || echo "$1" >> "$STATE"; }

ask() {
    (( ASSUME_YES )) && return 0
    local ans
    read -rp "$1 [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

# Run a named step once. Interactive steps are recorded in $STATE so reruns
# skip them; but the underlying actions are themselves idempotent, so even a
# forced rerun is safe.
step() {
    local name="$1"; shift

    if done_step "$name"; then
        log "[SKIP] $name (already done)"
        return 0
    fi

    echo
    echo "=== $name ==="

    if ask "Run this step?"; then
        "$@"
        mark_done "$name"
    else
        log "[SKIP] $name (declined)"
    fi
}

# --- AUR helper detection ----------------------------------------------------
detect_aur_helper() {
    if have paru; then echo paru
    elif have yay; then echo yay
    else return 1
    fi
}

# --- Steps -------------------------------------------------------------------
restore_packages() {
    have pacman || { warn "pacman missing; skipping"; return 0; }
    sudo pacman -Syu --noconfirm
    # --needed makes this idempotent: installed packages are skipped.
    # xargs guards against an empty list and long arg lists.
    xargs -a pkglist.txt -r sudo pacman -S --needed --noconfirm --
}

restore_aur() {
    local helper
    if ! helper=$(detect_aur_helper); then
        warn "No AUR helper (paru/yay) found; install one first. Skipping AUR."
        return 0
    fi
    log "Using AUR helper: $helper"
    xargs -a aurlist.txt -r "$helper" -S --needed --noconfirm --
}

restore_flatpaks() {
    have flatpak || { warn "flatpak missing; skipping"; return 0; }
    flatpak remote-add --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo || true
    # `flatpak install` is idempotent for already-installed apps.
    while read -r app; do
        [[ -z "$app" || "$app" == \#* ]] && continue
        flatpak install -y --noninteractive flathub "$app" || \
            warn "could not install flatpak: $app"
    done < flatpaks.txt
}

# Enable each unit only if not already enabled. Templated units (foo@.service)
# and units without an [Install] section are skipped with a warning rather
# than aborting the whole run.
enable_units() {
    local scope="$1" file="$2"       # scope: "system" | "user"
    local sctl=(systemctl)
    [[ "$scope" == "user" ]] && sctl=(systemctl --user)

    [[ -f "$file" ]] || { warn "$file missing; skipping"; return 0; }

    while read -r unit; do
        [[ -z "$unit" || "$unit" == \#* ]] && continue
        # Skip bare template units — they can't be enabled without an instance.
        [[ "$unit" == *@.* ]] && { log "skip template unit $unit"; continue; }

        if "${sctl[@]}" is-enabled --quiet "$unit" 2>/dev/null; then
            continue
        fi
        if [[ "$scope" == "system" ]]; then
            sudo systemctl enable "$unit" 2>/dev/null \
                && log "enabled $unit" \
                || warn "could not enable $unit (missing or static)"
        else
            systemctl --user enable "$unit" 2>/dev/null \
                && log "enabled (user) $unit" \
                || warn "could not enable user unit $unit (missing or static)"
        fi
    done < "$file"
}

restore_system_services() { enable_units system enabled-services.txt; }
restore_user_services()   { enable_units user   user-services.txt; }

restore_etc() {
    if [[ ! -f etc-configs.tar.gz ]]; then
        warn "etc-configs.tar.gz not present (generate with ./generate.sh --etc). Skipping."
        return 0
    fi
    # Overwriting /etc unattended is dangerous — never auto-run it, even with --yes.
    if (( ASSUME_YES )); then
        warn "Skipping /etc restore in non-interactive mode. Run ./restore.sh interactively to apply it."
        return 0
    fi
    warn "About to extract etc-configs.tar.gz into /. Review carefully!"
    ask "Proceed extracting into /?" || return 0
    sudo tar xzf etc-configs.tar.gz -C /
}

# --- Run ---------------------------------------------------------------------
step "official-packages" restore_packages
step "aur-packages"      restore_aur
step "flatpaks"          restore_flatpaks
step "system-services"   restore_system_services
step "user-services"     restore_user_services
step "etc-configs"       restore_etc

echo
log "Migration complete. Safe to rerun."
log "Home dotfiles are managed by chezmoi (\`chezmoi apply\`), not this script."
