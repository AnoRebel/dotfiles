#!/bin/bash

set -eu

# Sync and install prerequisites (--needed keeps this idempotent).
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm --needed \
  zsh eza bat fzf fd ripgrep zoxide git-credential-manager \
  git lazydocker lazygit github-cli jq zellij age gnupg \
  curl wget rsync tree btop fastfetch chezmoi just sops

# Configure git-credential-manager only once (it edits ~/.gitconfig each run).
if command -v git-credential-manager >/dev/null 2>&1 \
   && ! git config --global --get credential.helper | grep -q "credential-manager"; then
  echo "Configuring git-credential-manager..."
  git-credential-manager configure
fi

# Install oh-my-zsh (unattended) if missing — the plugins/theme below live under it.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing oh-my-zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
	echo "Installing Zsh Autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
fi

if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
	echo "Installing Zsh Syntax Highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
fi

if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-completions" ]]; then
	echo "Installing Zsh Completions..."
	git clone https://github.com/zsh-users/zsh-completions $HOME/.oh-my-zsh/custom/plugins/zsh-completions
fi

if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-history-substring-search" ]]; then
	echo "Installing Zsh Substring Search..."
	git clone https://github.com/zsh-users/zsh-history-substring-search $HOME/.oh-my-zsh/custom/plugins/zsh-history-substring-search
fi

# Set zsh as default shell if not already (best-effort; may need a password).
zsh_path="$(command -v zsh)"
if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]; then
  echo "Setting zsh as default shell..."
  chsh -s "$zsh_path" || echo "chsh failed (run 'chsh -s $zsh_path' manually)"
fi

# Add Powerlevel10k theme if not already installed
if [[ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
	echo "Installing Powerlevel10k theme..."
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/.oh-my-zsh/custom/themes/powerlevel10k
	# sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
fi
