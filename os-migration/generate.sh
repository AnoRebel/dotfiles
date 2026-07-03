#!/usr/bin/env bash
#
# generate.sh — (re)generate the os-migration manifest files.
#
# Produces clean, machine-parseable, sorted lists that restore.sh (and the
# chezmoi run_onchange_ hook) can consume idempotently. Run this whenever you
# install/remove packages or toggle services and want the migration snapshot
# to reflect the current machine.
#
#   ./generate.sh          # regenerate every manifest
#   ./generate.sh --etc    # additionally snapshot /etc into etc-configs.tar.gz
#
# Design notes:
#   * pkglist.txt   -> only NATIVE, explicitly-installed packages (pacman -Qqen)
#   * aurlist.txt   -> only FOREIGN/AUR explicitly-installed packages (pacman -Qqem)
#     Splitting them means `pacman -S` never chokes on AUR-only names, and the
#     AUR helper only handles what it must.
#   * *-services.txt -> bare unit names, one per line (no headers/columns/footer)
#   * Everything is `sort -u` so diffs are stable and the run_onchange_ hash is
#     deterministic (order changes don't retrigger the hook).

set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$0")")"

log() { printf '\033[1;34m[gen]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[gen]\033[0m %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

# --- Native explicitly-installed packages ------------------------------------
if have pacman; then
  log "Writing pkglist.txt (native explicit packages)"
  pacman -Qqen | sort -u > pkglist.txt

  log "Writing aurlist.txt (foreign/AUR explicit packages)"
  pacman -Qqem | sort -u > aurlist.txt
else
  warn "pacman not found; leaving pkglist.txt / aurlist.txt untouched"
fi

# --- Flatpaks ----------------------------------------------------------------
if have flatpak; then
  log "Writing flatpaks.txt"
  flatpak list --app --columns=application | sort -u > flatpaks.txt
else
  warn "flatpak not found; leaving flatpaks.txt untouched"
fi

# --- Enabled systemd units ---------------------------------------------------
# Bare unit names only. Templated units (getty@.service) and static/generated
# units are intentionally included if they show as `enabled`; restore filters
# what it can safely enable.
if have systemctl; then
  log "Writing enabled-services.txt (system units)"
  systemctl list-unit-files --state=enabled --no-legend --no-pager \
    | awk '{print $1}' | sort -u > enabled-services.txt

  log "Writing user-services.txt (user units)"
  systemctl --user list-unit-files --state=enabled --no-legend --no-pager 2>/dev/null \
    | awk '{print $1}' | sort -u > user-services.txt
else
  warn "systemctl not found; leaving service lists untouched"
fi

# --- Optional /etc snapshot --------------------------------------------------
# Home configs are managed by chezmoi, so we do NOT tar those. Only /etc, and
# only on request, since it needs root and careful review before restore.
if [[ "${1:-}" == "--etc" ]]; then
  log "Snapshotting /etc -> etc-configs.tar.gz (needs sudo)"
  sudo tar czf etc-configs.tar.gz \
    --exclude='/etc/ssl/private' \
    --exclude='*.pem' \
    --exclude='*.key' \
    -C / etc
  log "etc-configs.tar.gz written. Review its contents before restoring."
fi

log "Done. Review 'git diff' before committing."
