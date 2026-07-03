# dotfiles

Personal dotfiles for an **Arch Linux** desktop, managed with
[chezmoi](https://www.chezmoi.io/). Secrets are encrypted with
[age](https://age-encryption.org/); a companion `os-migration/` toolkit snapshots
and restores the full package/service set so a fresh machine can be rebuilt from
scratch.

## Table of Contents

- [Key Features](#key-features)
- [What Gets Managed](#what-gets-managed)
- [Prerequisites](#prerequisites)
- [Bootstrap](#bootstrap)
- [Architecture](#architecture)
  - [Naming Conventions](#naming-conventions)
  - [Run Script Order](#run-script-order)
- [Directory Structure](#directory-structure)
- [Encryption](#encryption)
- [OS Migration](#os-migration)
- [Day-to-Day Usage](#day-to-day-usage)
- [Shell Setup](#shell-setup)

## Key Features

- **Single source of truth** for shell, editor, WM, and app configs via chezmoi.
- **Encrypted secrets** (SSH keys, GitHub hosts, WakaTime, GTK bookmarks) with age.
- **Idempotent bootstrap** — a `run_once_before_` script installs prerequisites,
  oh-my-zsh, plugins, and Powerlevel10k; safe to re-run.
- **Full-machine restore** — `os-migration/` captures native packages, AUR
  packages, flatpaks, and enabled systemd units, and restores them idempotently.
- **Opt-in migration hook** — a `run_onchange_` script wires the restore into
  `chezmoi apply`, gated behind a `migrate` flag so it never fires on machines
  you don't want rebuilt.

## What Gets Managed

- **Shells:** `zsh` (primary, oh-my-zsh + Powerlevel10k), plus `bash` profiles.
- **Prompt/UX:** Powerlevel10k, atuin, zoxide, fzf, mise, a large oh-my-zsh
  plugin set.
- **Editors:** Neovim, Neovide.
- **Wayland desktop:** Hyprland, Niri, quickshell, mako, swaylock, swappy,
  kanshi, gammastep, rofi, and friends (see `dot_config/`).
- **Terminals:** Alacritty, Kitty, Ghostty, foot, rio.
- **CLI tooling configs:** lazygit, htop/btop, gh, mpd/ncmpcpp, yazi, superfile,
  and many more.
- **Personal scripts:** `~/.local/bin/` (37 helper scripts).
- **Secrets:** `~/.ssh/`, WakaTime, GitHub hosts, GTK bookmarks (all age-encrypted).

## Prerequisites

An Arch-based system with:

- `git`
- `chezmoi` (or install it during bootstrap — the init one-liner below can
  bootstrap it)
- Your **age identity key** at `~/.config/chezmoi/key.txt` (required to decrypt
  the encrypted files; keep it out of this repo).

Everything else (zsh, eza, bat, fzf, ripgrep, zoxide, lazygit, age, gnupg, …) is
installed by the prerequisites script during bootstrap.

## Bootstrap

On a fresh machine:

```bash
# Installs chezmoi (if needed), clones this repo, and applies it.
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply AnoRebel
```

Or, if chezmoi is already installed:

```bash
chezmoi init --apply https://github.com/AnoRebel/dotfiles.git
```

During `init` you'll be asked:

- **`migrate`** — whether to run the full OS restore
  (packages/AUR/flatpaks/services from `os-migration/`). Answer **no** on an
  existing machine you only want dotfiles on; **yes** on a fresh box you're
  rebuilding. You can flip it later:

  ```bash
  chezmoi init --promptBool migrate=true && chezmoi apply
  ```

### Decrypting secrets

Applying will fail to decrypt the `*.age` files unless your age key is present:

```bash
# Place your private age identity here before (or during) apply:
mkdir -p ~/.config/chezmoi
cp /path/to/key.txt ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
```

### Verify

```bash
chezmoi doctor          # environment sanity check
chezmoi managed | head  # what chezmoi controls
echo "$SHELL"           # should be .../zsh after re-login
git config --global --get user.email
```

## Architecture

### How chezmoi works

Source files live in this repo (`~/.local/share/chezmoi`). `chezmoi apply`
renders them (running templates, decrypting age files) into your home directory.
File *attributes* are encoded in filename prefixes.

### Naming Conventions

| Prefix / suffix        | Meaning                                                    |
| ---------------------- | ---------------------------------------------------------- |
| `dot_`                 | Becomes a leading `.` (e.g. `dot_zshrc` → `~/.zshrc`)      |
| `private_`             | Target file gets `0600`/dir `0700` perms                  |
| `executable_`          | Target file gets the executable bit                        |
| `encrypted_`           | Decrypted with age on apply                                 |
| `.tmpl`                | Rendered as a Go text/template                              |
| `run_once_`            | Script run once per machine (tracked by content hash)      |
| `run_onchange_`        | Script re-run whenever its rendered content changes        |
| `before_` / `after_`   | Runs before/after the rest of the apply                    |

`.chezmoiignore` excludes repo-only paths (`README.md`, `os-migration/`) from the
target so they never land in `$HOME`.

### Run Script Order

1. **`run_once_before_00-install-pre-requisites.sh`** — `pacman -Syu` + install
   core CLI tools; configure `git-credential-manager` (once); install oh-my-zsh
   unattended; clone zsh plugins (autosuggestions, syntax-highlighting,
   completions, history-substring-search) and Powerlevel10k; set zsh as the
   default shell. Every step is guarded, so re-running is a no-op where already
   done.
2. **(dotfiles are applied)**
3. **`run_onchange_after_50-os-migration.sh.tmpl`** — if `migrate=true`, runs
   `os-migration/restore.sh --yes`. It embeds a hash of every manifest, so
   regenerating any package/service list re-triggers the restore (installing only
   the new items, since the restore is idempotent).

> `run_once_` scripts execute once per machine (chezmoi tracks them by hash). To
> force a re-run:
>
> ```bash
> chezmoi state delete-bucket --bucket=scriptState
> chezmoi apply
> ```

## Directory Structure

```
~/.local/share/chezmoi/
├── .chezmoi.toml.tmpl                       # config template (prompts, age, editor, diff/merge)
├── .chezmoiignore                           # paths excluded from $HOME (README, os-migration)
├── dot_zshrc / dot_zshenv / dot_zprofile    # zsh
├── dot_bashrc / dot_bash_profile / dot_profile
├── dot_gitconfig
├── executable_dot_face
├── encrypted_dot_wakatime.cfg.age           # encrypted WakaTime config
├── dot_config/                              # the bulk of app configs (Hyprland, Niri, nvim, …)
├── private_dot_ssh/                         # SSH config + keys (encrypted, 0600)
│   ├── encrypted_config.age
│   ├── encrypted_private_id_rsa.age
│   ├── encrypted_private_known_hosts.age
│   └── id_rsa.pub
├── private_dot_local/bin/                   # ~/.local/bin helper scripts
├── run_once_before_00-install-pre-requisites.sh
├── run_onchange_after_50-os-migration.sh.tmpl
└── os-migration/                            # full-machine snapshot/restore toolkit
    ├── generate.sh                          # (re)generate the manifests below
    ├── restore.sh                           # idempotent restore
    ├── pkglist.txt                          # native explicit packages (pacman -Qqen)
    ├── aurlist.txt                          # AUR explicit packages (pacman -Qqem)
    ├── flatpaks.txt                         # flatpak app IDs
    ├── enabled-services.txt                 # enabled system units
    └── user-services.txt                    # enabled user units
```

## Encryption

Secrets are encrypted with **age**, configured in `.chezmoi.toml.tmpl`:

- **Identity:** `~/.config/chezmoi/key.txt` (never committed).
- **Recipient:** the public key baked into the config template.

Encrypted files in this repo:

| Encrypted source                                   | Decrypts to                     |
| -------------------------------------------------- | ------------------------------- |
| `encrypted_dot_wakatime.cfg.age`                   | `~/.wakatime.cfg`               |
| `private_dot_ssh/encrypted_config.age`             | `~/.ssh/config`                 |
| `private_dot_ssh/encrypted_private_id_rsa.age`     | `~/.ssh/id_rsa`                 |
| `private_dot_ssh/encrypted_private_known_hosts.age`| `~/.ssh/known_hosts`            |
| `dot_config/gh/encrypted_executable_hosts.yml.age` | `~/.config/gh/hosts.yml`        |
| `dot_config/gtk-3.0/encrypted_bookmarks.age`       | `~/.config/gtk-3.0/bookmarks`   |

### Encrypt a new secret

```bash
chezmoi add --encrypt ~/.some/secret     # add + encrypt in one step
chezmoi edit ~/.some/secret              # edit decrypted, re-encrypts on save
```

## OS Migration

`os-migration/` rebuilds a machine's package and service set. It is **separate
from chezmoi's dotfile job** — home configs are owned by chezmoi, so migration
only handles packages, AUR, flatpaks, and enabled systemd units.

### Regenerating the manifests

Run whenever you install/remove packages or toggle services:

```bash
cd ~/.local/share/chezmoi/os-migration
./generate.sh            # refresh pkglist/aurlist/flatpaks/services (sorted, deduped)
./generate.sh --etc      # additionally snapshot /etc → etc-configs.tar.gz (needs sudo)
git -C .. diff           # review before committing
```

`generate.sh` writes clean, sorted, parseable lists:

- `pkglist.txt` — only **native** explicit packages, so `pacman -S` never chokes
  on AUR names.
- `aurlist.txt` — only **AUR** explicit packages.
- `*-services.txt` — bare unit names, one per line (no headers/columns/footers).

### Restoring

```bash
cd ~/.local/share/chezmoi/os-migration
./restore.sh             # interactive — asks before each step
./restore.sh --yes       # non-interactive — used by the chezmoi hook
```

The restore is fully idempotent:

- packages/AUR/flatpaks use `--needed`, so present items are skipped;
- services are enabled only if not already enabled (template units are skipped);
- a `.restore-state` file records completed interactive steps to avoid re-prompting
  (delete a line to redo a step);
- the AUR helper is auto-detected (**paru** preferred, then **yay**);
- the `/etc` restore is **never** run unattended, even with `--yes`.

### Automatic restore via chezmoi

When `migrate=true`, `run_onchange_after_50-os-migration.sh.tmpl` invokes
`restore.sh --yes` after apply, and re-runs whenever any manifest changes.

## Day-to-Day Usage

```bash
chezmoi edit ~/.zshrc          # edit source, apply on save
chezmoi apply                  # apply all pending changes
chezmoi apply --dry-run -v     # preview
chezmoi diff                   # show source vs target differences
chezmoi status                 # short status of differing files

chezmoi cd                     # cd into the source repo
# ... git add / commit / push ...

chezmoi update                 # git pull + apply (on another machine)
```

The config sets the editor to `avim -f` and the diff pager to `hunk diff --watch`
(see `.chezmoi.toml.tmpl`).

## Shell Setup

`zsh` with **oh-my-zsh** and the **Powerlevel10k** theme. Highlights from
`dot_zshrc`:

- **Plugins:** `git`, `git-extras`, `jj`, `fzf-tab`, `zsh-autosuggestions`,
  `zsh-completions`, `zsh-syntax-highlighting`, `fzf`, `bgnotify`, `docker`,
  `podman`, `uv`, `poetry-env`, `systemd`, `command-not-found`,
  `zsh-interactive-cd`, and more.
- **Integrations:** `mise` (runtime versions), `zoxide` (smart cd), `fzf`
  (fuzzy find + `--zsh` keybindings), atuin (shell history), plus optional
  `forgit`, `emoji-cli`, `ghcup`, and Kitty completions when present.
- **Helpers:** `rga-fzf` (ripgrep-all + fzf) and an fzf-driven Neovim config
  switcher.

Plugins and the theme are installed by the prerequisites script on first apply.
