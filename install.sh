#!/usr/bin/env bash
# =============================================================================
# install.sh — WSL2 Ubuntu Development Environment Setup
# =============================================================================
# Usage:
#   chmod +x install.sh
#   ./install.sh
#
# What this does:
#   1. Updates system packages
#   2. Installs core dev tools, languages, and utilities
#   3. Installs Zsh + Oh My Zsh
#   4. Installs Powerlevel10k theme + useful plugins
#   5. Symlinks dotfiles configs (.zshrc, .gitconfig, etc.)
#   6. Installs Python tooling (pyenv, pipx)
#   7. Installs Node.js via nvm
#   8. Installs Docker CLI tools
#   9. Installs GitHub CLI
#  10. Applies final shell configuration
#
# Safe to re-run — all steps check before acting (idempotent)
# =============================================================================
 
set -euo pipefail
# set -e  → exit immediately if any command fails
# set -u  → treat unset variables as errors (catches typos like $HOEM)
# set -o pipefail → if any command in a pipe fails, the whole pipe fails
#                   (without this, "failing_cmd | echo ok" would succeed)
 
# =============================================================================
# COLOUR OUTPUT HELPERS
# =============================================================================
# \033[ is the ANSI escape code prefix
# 0;32m = normal green, 0;34m = blue, 0;33m = yellow, 0;31m = red, 0m = reset
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'
 
# Functions to print styled messages
info()    { echo -e "${BLUE}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
header()  { echo -e "\n${BOLD}${BLUE}==> $*${RESET}"; }
 
# =============================================================================
# HELPER FUNCTIONS
# =============================================================================
 
# command_exists: checks if a program is available on PATH
# Usage: if command_exists docker; then ...
command_exists() {
    command -v "$1" &>/dev/null
    # command -v prints the path to a program if it exists
    # &>/dev/null redirects both stdout and stderr to /dev/null (silence output)
    # returns 0 (true) if found, 1 (false) if not
}
 
# confirm: asks user a yes/no question, returns true on yes
# Usage: if confirm "Install Python?"; then ...
confirm() {
    read -r -p "${1} [y/N] " response
    # -r prevents backslash interpretation
    # -p shows a prompt before reading input
    [[ "${response,,}" =~ ^(yes|y)$ ]]
    # ${response,,} lowercases the response
    # =~ is regex match; ^(yes|y)$ matches "y" or "yes" exactly
}
 
# symlink: creates a symlink, backing up any existing file first
# Usage: symlink ~/dotfiles/.zshrc ~/.zshrc
symlink() {
    local src="$1"   # source: file in your dotfiles repo
    local dst="$2"   # destination: where it should live (e.g. ~/.zshrc)
 
    if [[ -f "$dst" && ! -L "$dst" ]]; then
        # -f = file exists, -L = is already a symlink
        # If a real file exists (not a symlink), back it up
        warn "Backing up existing $dst → ${dst}.backup"
        mv "$dst" "${dst}.backup"
    fi
 
    ln -sf "$src" "$dst"
    # ln -s creates a symbolic link (pointer), -f forces overwrite if exists
    success "Linked $src → $dst"
}
 
# =============================================================================
# CONFIGURATION — edit these to match your setup
# =============================================================================
 
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# BASH_SOURCE[0] is the path to this script
# dirname strips the filename, leaving the directory
# cd + pwd gives us the absolute path (resolves any ../ or symlinks)
 
GITHUB_USERNAME="Shazzy111"    # ← change this
GIT_EMAIL="khososhahzeb@gmail.com"               # ← change this
GIT_NAME="Shazzy111"                     # ← change this
 
# =============================================================================
# BANNER
# =============================================================================
 
echo -e "${BOLD}"
echo "  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗"
echo "  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝"
echo "  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗"
echo "  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║"
echo "  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║"
echo "  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝"
echo -e "${RESET}"
echo -e "  WSL2 Ubuntu Dev Environment Setup"
echo -e "  Running from: ${BLUE}${DOTFILES_DIR}${RESET}"
echo ""
 
# =============================================================================
# STEP 1 — SYSTEM UPDATE
# =============================================================================
header "Step 1/10 — System update"
 
info "Updating package lists..."
sudo apt-get update -qq
# -qq = extra quiet, only shows errors
 
info "Upgrading installed packages..."
sudo apt-get upgrade -y -qq
 
success "System up to date"
 
# =============================================================================
# STEP 2 — CORE PACKAGES
# =============================================================================
header "Step 2/10 — Core packages"
 
# Array of packages to install
PACKAGES=(
    # Shell & terminal
    zsh
    zsh-syntax-highlighting
    zsh-autosuggestions
 
    # Version control
    git
    git-extras          # extra git commands (git summary, git undo, etc.)
 
    # Network tools
    curl
    wget
    httpie              # user-friendly curl alternative
    net-tools           # ifconfig, netstat
    dnsutils            # dig, nslookup
    nmap                # network scanner
    traceroute
    iputils-ping
 
    # File tools
    unzip
    zip
    tar
    tree                # show directory structure as a tree
    jq                  # parse and manipulate JSON from the terminal
    fzf                 # fuzzy finder — search files/history interactively
    bat                 # better cat with syntax highlighting
    ripgrep             # faster grep (command: rg)
    fd-find             # faster find (command: fdfind)
    htop                # interactive process viewer
    ncdu                # interactive disk usage analyser
 
    # Build tools
    build-essential     # gcc, g++, make
    pkg-config
    cmake
 
    # Editors
    nano
    vim
 
    # System
    ca-certificates     # SSL certificates
    gnupg               # GPG encryption/signing
    lsb-release         # Linux Standard Base info
    software-properties-common
    apt-transport-https
)
 
info "Installing ${#PACKAGES[@]} packages..."
# ${#PACKAGES[@]} = length of array
 
sudo apt-get install -y -qq "${PACKAGES[@]}"
# "${PACKAGES[@]}" expands all array elements as separate quoted arguments
 
# Create alias for fd (installed as fdfind to avoid conflict)
if command_exists fdfind && ! command_exists fd; then
    sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
    success "Created fd → fdfind alias"
fi
 
success "Core packages installed"
 
# =============================================================================
# STEP 3 — ZSH + OH MY ZSH
# =============================================================================
header "Step 3/10 — Zsh + Oh My Zsh"
 
# Install Oh My Zsh only if not already installed
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing Oh My Zsh..."
    # RUNZSH=no prevents the installer from switching to zsh mid-script
    # CHSH=no prevents it from running chsh (we'll do this ourselves)
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    success "Oh My Zsh installed"
else
    info "Oh My Zsh already installed — skipping"
fi
 
# Install Powerlevel10k theme
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ ! -d "$P10K_DIR" ]]; then
    info "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    # --depth=1 = shallow clone, only downloads the latest snapshot
    #             much faster, no full git history needed for a theme
    success "Powerlevel10k installed"
else
    info "Powerlevel10k already installed — skipping"
fi
 
# Install zsh-autosuggestions plugin (fish-like suggestions as you type)
ZSH_SUGGEST_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
if [[ ! -d "$ZSH_SUGGEST_DIR" ]]; then
    info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_SUGGEST_DIR"
    success "zsh-autosuggestions installed"
fi
 
# Install zsh-syntax-highlighting (highlights valid commands in green)
ZSH_HIGHLIGHT_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
if [[ ! -d "$ZSH_HIGHLIGHT_DIR" ]]; then
    info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_HIGHLIGHT_DIR"
    success "zsh-syntax-highlighting installed"
fi
 
# Set zsh as default shell
if [[ "$SHELL" != "$(which zsh)" ]]; then
    info "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
    success "Default shell set to zsh (takes effect on next login)"
else
    info "Zsh is already the default shell"
fi
 
# =============================================================================
# STEP 4 — SYMLINK DOTFILES CONFIGS
# =============================================================================
header "Step 4/10 — Symlinking config files"
 
# Only symlink files that actually exist in the dotfiles repo
# This way the script works even if you haven't created all configs yet
 
[[ -f "$DOTFILES_DIR/.zshrc" ]]      && symlink "$DOTFILES_DIR/.zshrc"      "$HOME/.zshrc"
[[ -f "$DOTFILES_DIR/.gitconfig" ]]  && symlink "$DOTFILES_DIR/.gitconfig"  "$HOME/.gitconfig"
[[ -f "$DOTFILES_DIR/.p10k.zsh" ]]   && symlink "$DOTFILES_DIR/.p10k.zsh"   "$HOME/.p10k.zsh"
[[ -f "$DOTFILES_DIR/.vimrc" ]]      && symlink "$DOTFILES_DIR/.vimrc"       "$HOME/.vimrc"
 
# SSH config (not keys — just the config file with connection shortcuts)
if [[ -f "$DOTFILES_DIR/.ssh/config" ]]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"     # SSH directory must be 700 (owner read/write/execute only)
    symlink "$DOTFILES_DIR/.ssh/config" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"  # SSH config must be 600 (owner read/write only)
fi
 
success "Dotfiles linked"
 
# =============================================================================
# STEP 5 — GIT CONFIGURATION
# =============================================================================
header "Step 5/10 — Git configuration"
 
# Only set if not already configured (respects existing settings)
current_name=$(git config --global user.name 2>/dev/null || echo "")
current_email=$(git config --global user.email 2>/dev/null || echo "")
 
if [[ -z "$current_name" ]]; then
    git config --global user.name "$GIT_NAME"
    success "Git name set: $GIT_NAME"
fi
 
if [[ -z "$current_email" ]]; then
    git config --global user.email "$GIT_EMAIL"
    success "Git email set: $GIT_EMAIL"
fi
 
# These are always safe to set
git config --global init.defaultBranch main
git config --global core.editor "code --wait"
git config --global pull.rebase false       # merge on pull (not rebase)
git config --global core.autocrlf input     # handle Windows line endings
git config --global push.autoSetupRemote true  # auto set upstream on first push
git config --global alias.lg "log --oneline --graph --decorate --all"
git config --global alias.st "status -sb"   # short status with branch info
git config --global alias.undo "reset HEAD~1 --mixed"  # undo last commit, keep changes
 
success "Git configured"
 
# =============================================================================
# STEP 6 — PYTHON TOOLING (pyenv)
# =============================================================================
header "Step 6/10 — Python (pyenv)"
 
if ! command_exists pyenv; then
    info "Installing pyenv..."
 
    # pyenv dependencies
    sudo apt-get install -y -qq \
        libssl-dev libffi-dev zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev liblzma-dev \
        libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev
 
    curl https://pyenv.run | bash
    # pyenv.run is the official pyenv installer
    # installs pyenv + pyenv-update + pyenv-virtualenv
 
    # Add pyenv to PATH for the rest of this script
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
 
    success "pyenv installed"
 
    info "Installing Python 3.12 (latest stable)..."
    pyenv install 3.12 --skip-existing
    pyenv global 3.12
    # global = use this version everywhere by default
    success "Python $(python --version) set as global"
else
    info "pyenv already installed — skipping"
fi
 
# Install pipx (installs Python CLI tools in isolated environments)
if ! command_exists pipx; then
    info "Installing pipx..."
    python -m pip install --user pipx --quiet
    python -m pipx ensurepath
    success "pipx installed"
fi
 
# Install useful Python CLI tools via pipx
PYTHON_TOOLS=(
    black           # code formatter
    ruff            # fast linter (replaces flake8, pylint)
    httpie          # HTTP client (http command)
    ipython         # better Python REPL
    poetry          # modern dependency management
)
 
for tool in "${PYTHON_TOOLS[@]}"; do
    if ! command_exists "$tool"; then
        info "Installing $tool..."
        pipx install "$tool" --quiet
    fi
done
 
success "Python tooling ready"
 
# =============================================================================
# STEP 7 — NODE.JS (nvm)
# =============================================================================
header "Step 7/10 — Node.js (nvm)"
 
if [[ ! -d "$HOME/.nvm" ]]; then
    info "Installing nvm (Node Version Manager)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    # nvm is a shell function, not a binary — needs to be sourced to use it
    success "nvm installed"
fi
 
# Load nvm into current session so we can use it immediately
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
# -s = file exists and is not empty
 
if command_exists nvm; then
    info "Installing Node.js LTS..."
    nvm install --lts
    nvm use --lts
    nvm alias default 'lts/*'
    success "Node $(node --version) installed (npm $(npm --version))"
 
    # Install global npm tools
    npm install -g \
        pnpm \          # faster npm alternative
        typescript \    # TypeScript compiler
        ts-node         # run TypeScript directly
fi
 
# =============================================================================
# STEP 8 — DOCKER (CLI + Engine)
# =============================================================================
header "Step 8/10 — Docker"
 
if ! command_exists docker; then
    info "Installing Docker Engine..."
 
    # Add Docker's official GPG key (verifies packages are authentic)
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    # gpg --dearmor converts from ASCII armored to binary format
    # needed so apt can verify the packages
 
    # Add Docker's apt repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    # dpkg --print-architecture → amd64 (your CPU architecture)
    # /etc/os-release contains distro info like VERSION_CODENAME=jammy
 
    sudo apt-get update -qq
    sudo apt-get install -y -qq \
        docker-ce \              # Docker Engine
        docker-ce-cli \          # Docker CLI
        containerd.io \          # container runtime
        docker-buildx-plugin \   # BuildKit (advanced image building)
        docker-compose-plugin    # docker compose v2 (note: no hyphen)
 
    # Add your user to the docker group (run docker without sudo)
    sudo usermod -aG docker "$USER"
    # -aG = append to group (don't remove from other groups)
    # Takes effect on next login — for now use: newgrp docker
 
    success "Docker installed"
    warn "Log out and back in (or run 'newgrp docker') to use docker without sudo"
else
    info "Docker already installed — skipping"
    docker --version
fi
 
# =============================================================================
# STEP 9 — GITHUB CLI (gh)
# =============================================================================
header "Step 9/10 — GitHub CLI"
 
if ! command_exists gh; then
    info "Installing GitHub CLI..."
 
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) \
        signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
        https://cli.github.com/packages stable main" | \
        sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
 
    sudo apt-get update -qq
    sudo apt-get install -y -qq gh
 
    success "GitHub CLI installed"
    info "Authenticate with: gh auth login"
else
    info "GitHub CLI already installed — skipping"
fi
 
# =============================================================================
# STEP 10 — WRITE .zshrc (if one doesn't exist in dotfiles)
# =============================================================================
header "Step 10/10 — Shell configuration"
 
ZSHRC="$DOTFILES_DIR/.zshrc"
 
if [[ ! -f "$ZSHRC" ]]; then
    info "Writing default .zshrc to dotfiles directory..."
    cat > "$ZSHRC" << 'EOF'
# =============================================================================
# .zshrc — Zsh Configuration
# Managed by dotfiles (github.com/YOURUSERNAME/dotfiles)
# =============================================================================
 
# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"
 
# Theme — Powerlevel10k
# Run `p10k configure` to reconfigure interactively
ZSH_THEME="powerlevel10k/powerlevel10k"
 
# Load p10k instant prompt (speeds up shell startup)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
 
# Oh My Zsh plugins
plugins=(
    git                     # git aliases and functions
    docker                  # docker aliases + completion
    docker-compose          # compose aliases
    python                  # python aliases
    pip                     # pip completion
    sudo                    # press ESC twice to prefix last command with sudo
    zsh-autosuggestions     # fish-like suggestions (grey text)
    zsh-syntax-highlighting # green = valid command, red = not found
    fzf                     # fuzzy finder integration
)
 
source "$ZSH/oh-my-zsh.sh"
 
# =============================================================================
# ENVIRONMENT VARIABLES
# =============================================================================
export EDITOR="code --wait"     # default text editor
export VISUAL="code --wait"
export PAGER="less"
export LANG="en_US.UTF-8"
 
# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv &>/dev/null && eval "$(pyenv init -)"
 
# nvm
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
 
# Local binaries (pipx installs here)
export PATH="$HOME/.local/bin:$PATH"
 
# =============================================================================
# NAVIGATION ALIASES
# =============================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias ll='ls -lah'              # long list, all files, human sizes
alias la='ls -A'                # all files including hidden
alias l='ls -CF'
alias lt='ls -lth'              # sort by modification time (newest first)
 
# Use bat instead of cat (syntax highlighting)
command -v bat &>/dev/null && alias cat='bat'
 
# Use fd instead of find
command -v fd &>/dev/null && alias find='fd'
 
# =============================================================================
# GIT ALIASES
# =============================================================================
alias gs='git status -sb'               # short status with branch
alias ga='git add .'                    # stage everything
alias gap='git add -p'                  # interactive staging (patch)
alias gc='git commit -m'               # commit with message
alias gca='git commit --amend'         # amend last commit
alias gp='git push'                    # push
alias gpf='git push --force-with-lease' # safer force push
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'                    # unstaged changes
alias gds='git diff --staged'          # staged changes
alias gb='git branch'                  # list branches
alias gco='git checkout'               # switch branches/files
alias gsw='git switch'                 # modern branch switching
alias gst='git stash'                  # stash changes
alias gstp='git stash pop'             # apply + drop latest stash
alias gundo='git reset HEAD~1 --mixed' # undo last commit, keep changes
 
# =============================================================================
# DOCKER ALIASES
# =============================================================================
alias d='docker'
alias dc='docker compose'
alias dcu='docker compose up -d'        # start in background
alias dcd='docker compose down'         # stop and remove containers
alias dcl='docker compose logs -f'      # follow logs
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias di='docker images'
alias dex='docker exec -it'            # interactive shell into container
 
# =============================================================================
# SYSTEM ALIASES
# =============================================================================
alias update='sudo apt update && sudo apt upgrade -y'
alias ports='ss -tulnp'                # show listening ports
alias myip='curl -s ifconfig.me'       # your public IP
alias localip='ip route get 1 | awk "{print \$7}"'
alias path='echo $PATH | tr ":" "\n"'  # show PATH one entry per line
alias reload='source ~/.zshrc'         # reload config without restart
alias df='df -h'                       # disk usage, human readable
alias du='du -h'                       # directory size, human readable
alias free='free -h'                   # memory usage, human readable
alias top='htop'                       # replace top with htop
 
# =============================================================================
# FUNCTIONS
# =============================================================================
 
# mkcd: make a directory and cd into it immediately
mkcd() {
    mkdir -p "$1" && cd "$1"
}
 
# extract: extract any archive type with one command
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1"    ;;
            *.tar.gz)  tar xzf "$1"    ;;
            *.tar.xz)  tar xJf "$1"    ;;
            *.bz2)     bunzip2 "$1"    ;;
            *.gz)      gunzip "$1"     ;;
            *.tar)     tar xf "$1"     ;;
            *.zip)     unzip "$1"      ;;
            *.7z)      7z x "$1"       ;;
            *)         echo "Cannot extract '$1'" ;;
        esac
    else
        echo "'$1' is not a file"
    fi
}
 
# serve: start a quick HTTP server in the current directory
serve() {
    local port="${1:-8000}"
    python -m http.server "$port"
}
 
# gi: generate a .gitignore from gitignore.io
gi() {
    curl -sL "https://www.toptal.com/developers/gitignore/api/$*"
}
 
# up: docker compose up shortcut that also shows logs
up() {
    docker compose up -d "$@" && docker compose logs -f
}
 
# =============================================================================
# HISTORY SETTINGS
# =============================================================================
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_DUPS      # don't save duplicate commands
setopt HIST_IGNORE_SPACE     # don't save commands starting with a space
setopt SHARE_HISTORY         # share history between terminal sessions
setopt HIST_VERIFY           # show command before running from history
 
# =============================================================================
# FZF CONFIGURATION (fuzzy finder)
# =============================================================================
if command -v fzf &>/dev/null; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null || true
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    # Ctrl+R = fuzzy search command history
    # Ctrl+T = fuzzy search files
    # Alt+C  = fuzzy search and cd into directories
fi
 
# =============================================================================
# POWERLEVEL10K
# =============================================================================
# Run `p10k configure` to regenerate this file interactively
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
EOF
 
    symlink "$ZSHRC" "$HOME/.zshrc"
    success ".zshrc written and linked"
else
    info ".zshrc already exists in dotfiles — skipping (not overwriting your config)"
fi
 
# =============================================================================
# DONE
# =============================================================================
 
echo ""
echo -e "${BOLD}${GREEN}============================================${RESET}"
echo -e "${BOLD}${GREEN}  Setup complete!${RESET}"
echo -e "${BOLD}${GREEN}============================================${RESET}"
echo ""
echo -e "  ${BOLD}Next steps:${RESET}"
echo -e "  ${BLUE}1.${RESET} Close and reopen your terminal (apply shell change)"
echo -e "  ${BLUE}2.${RESET} Run ${BOLD}p10k configure${RESET} to set up your prompt theme"
echo -e "  ${BLUE}3.${RESET} Run ${BOLD}gh auth login${RESET} to authenticate GitHub CLI"
echo -e "  ${BLUE}4.${RESET} Run ${BOLD}newgrp docker${RESET} to use Docker without logging out"
echo -e "  ${BLUE}5.${RESET} Edit ${BOLD}~/.zshrc${RESET} to customise further"
echo ""
echo -e "  Dotfiles directory: ${BLUE}${DOTFILES_DIR}${RESET}"
echo ""