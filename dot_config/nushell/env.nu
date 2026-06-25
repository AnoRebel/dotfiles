# Nushell Environment Config File
# Ported from .zshenv + tool init sections of .zshrc
# Nushell 0.111.0

# =============================================================================
# TOOL INIT FILE GENERATION
# =============================================================================
# Official pattern: save init output to a .nu file, then source/use it in config.nu.
# If a tool isn't installed, write an empty file so `source` doesn't fail.

let nu_conf = $nu.default-config-dir

# mise — Official Nushell pattern (https://mise.jdx.dev/installing-mise)
# Regenerate mise.nu on each shell start so hooks stay current with mise version
if (which mise | is-not-empty) {
    let mise_path = $nu.default-config-dir | path join "mise.nu"
    ^mise activate nu | save -f $mise_path
}

# =============================================================================
# PATH CONFIGURATION (from .zshenv)
# =============================================================================
# In Nushell, PATH is a list. Use `path add` from std to prepend entries.
use std/util "path add"

# User private bins (prepend for priority)
path add '~/.local/bin'
path add '~/bin'

# DuckDB
let duckdb_path = $"($env.HOME)/.duckdb/cli/latest"
if ($duckdb_path | path exists) { path add $duckdb_path }

# Go
path add '/usr/local/go/bin'
$env.GOPATH = $"($env.HOME)/go"
let gopath_bin = $"($env.GOPATH)/bin"
if ($gopath_bin | path exists) { path add $gopath_bin }

# Cargo / Rust
path add '~/.cargo/bin'

# Bun
$env.BUN_INSTALL = $"($env.HOME)/.bun"
path add '~/.bun/bin'

# Deno
$env.DENO_INSTALL = $"($env.HOME)/.deno"
path add '~/.deno/bin'

# Turso
let turso_path = $"($env.HOME)/.turso"
if ($turso_path | path exists) { path add $turso_path }

# Bob (Neovim version manager)
let bob_path = $"($env.HOME)/.local/share/bob/nvim-bin"
if ($bob_path | path exists) { path add $bob_path }

# .NET tools
path add '~/.dotnet/tools'

# Dart
path add '/usr/lib/dart/bin'

# Flutter
path add '~/flutter/bin'

# Yarn
path add '~/.yarn/bin'
path add '~/.config/yarn/global/node_modules/.bin'

# GHCup (Haskell)
path add '~/.ghcup/bin'

# =============================================================================
# ENVIRONMENT VARIABLES (from .zshrc)
# =============================================================================

$env.DOTBARE_DIR = $"($env.HOME)/.dotfiles"
$env.DOTBARE_TREE = $env.HOME
$env.EDITOR = "avim"
$env.VISUAL = "avim"
$env.BROWSER = "zen-browser"
$env.PLAYER = "celluloid"
$env.IMAGEVIEWER = "sxiv"
$env.TERMINAL = "kitty"
$env.MUSICER = "mpv"

# .NET telemetry
$env.DOTNET_CLI_TELEMETRY_OPTOUT = true

# Nix XDG data
let nix_share = $"($env.HOME)/.nix-profile/share"
if ($nix_share | path exists) {
    $env.XDG_DATA_DIRS = $"($nix_share):($env.XDG_DATA_DIRS | default '')"
}

# Erlang
$env.ERL_AFLAGS = "-kernel shell_history enabled"
# Dynamic KERL_CONFIGURE_OPTIONS (only set if pacman is available)
if (which pacman | is-not-empty) {
    let odbc_ver = (^pacman -Q unixodbc | split row ' ' | get 1)
    $env.KERL_CONFIGURE_OPTIONS = $"--with-odbc=/var/lib/pacman/local/unixodbc-($odbc_ver)"
}

# FZF configuration (from .zshrc)
$env.FZF_CTRL_T_OPTS = "--preview 'bat --color=always -n --line-range :400 {}'"
$env.FZF_ALT_C_OPTS = "--preview 'eza --tree --icons --color=always {} | head -200'"

# =============================================================================
# ENV CONVERSIONS — how Nushell parses PATH from inherited environment
# =============================================================================

$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
    "Path": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
}

# =============================================================================
# MODULE / SCRIPT SEARCH PATHS
# =============================================================================

$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts')
]

$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins')
]
