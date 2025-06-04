#!/usr/bin/env bash
# This file is used to store commands to run at creation of login shells 
# agnosticly of which type of shell is being used.

TYPE_OF_SHELL=$(basename "$SHELL")

echo '===================================================================='
printf "Initializing shell configuration for %s %s %s ...\n" "$TYPE_OF_SHELL" "$BASH_VERSION" "$ZSH_VERSION"
echo '===================================================================='

prepend_to_path() {
    dir="$1"
    case ":$PATH:" in
        *":$dir:"*) 
            ;;
        *)
            echo "Prepending $dir to PATH."
            export PATH="$dir:$PATH"
            ;;
    esac
}

pretty_path() {
    echo "PATH directories:"
    echo "-----------------"
    
    # Split PATH by colon and process each directory - compatible with both Bash and Zsh
    if [ "$TYPE_OF_SHELL" = "bash" ]; then
        IFS=':' read -ra PATHS <<< "$PATH"
    else
        # Zsh compatible way to split the PATH
        PATHS=(${(s/:/)PATH})
    fi
    
    # Count for numbering
    count=1
    
    for dir in "${PATHS[@]}"; do
        # Check if directory exists
        if [ -d "$dir" ]; then
            dir_status="✅"
        else
            dir_status="❌"
        fi
        
        # Count executable files in the directory if it exists
        if [ -d "$dir" ]; then
            file_count=$(find "$dir" -maxdepth 1 -type f -executable 2>/dev/null | wc -l)
            files_info="($file_count executables)"
        else
            files_info="(directory doesn't exist)"
        fi
        
        # Print with formatting
        printf "%3d. %s %s %s\n" "$count" "$dir_status" "$dir" "$files_info"
        
        count=$((count+1))
    done
    
    echo "-----------------"
}

for dir in "$HOME/.local/bin" "$HOME/.local/share/go/bin"; do
    prepend_to_path "$dir"
done

pretty_path

# -----------------------------------------------------------------------------
# Custom command activations
# -----------------------------------------------------------------------------

if [ -z "$(command -v starship)" ]; then
    echo "starship is not installed."
else
    eval "$(starship init "${TYPE_OF_SHELL}")"
    # completions for starship
    eval "$(starship completions "${TYPE_OF_SHELL}")"
fi

# Atuin - command history manager
# checking that "$HOME/.atuin/bin/" directory exists
if [ ! -d "$HOME/.atuin/bin/" ]; then
    echo "Directory $HOME/.atuin/bin/ does not exist. Please install Atuin."
else
    . "$HOME/.atuin/bin/env"

    [[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
    eval "$(atuin init "${TYPE_OF_SHELL}" --disable-up-arrow)"
    
    eval "$(atuin gen-completions --shell "${TYPE_OF_SHELL}")"
fi

# -----------------------------------------------------------------------------
# Custom shell completions
# -----------------------------------------------------------------------------

## https://fx.wtf/install#autocomplete
# checking that fx is installed
if [ -z "$(command -v fx)" ]; then
    echo "fx is not installed."
else
    source <(fx --comp "${TYPE_OF_SHELL}")
    export FX_THEME="5"
fi

## UV
# checking that uv is installed
if [ -z "$(command -v uv)" ]; then
    echo "uv is not installed."
else
    eval "$(uv generate-shell-completion "${TYPE_OF_SHELL}")"
    eval "$(uvx --generate-shell-completion "${TYPE_OF_SHELL}")"
fi

## zoxide 
# checking that zoxide is installed
if [ -z "$(command -v zoxide)" ]; then
    echo "zoxide is not installed."
else
    eval "$(zoxide init "${TYPE_OF_SHELL}")"
fi

## chezmoi 
# checking that chezmoi is installed
if [ -z "$(command -v chezmoi)" ]; then
    echo "chezmoi is not installed."
else
    eval "$(chezmoi completion "${TYPE_OF_SHELL}")" 
fi

## gh
# checking that gh is installed
if [ -z "$(command -v gh)" ]; then
    echo "gh is not installed."
else
    eval "$(gh completion -s "${TYPE_OF_SHELL}")"
fi

## rclone 
# checking that rclone is installed
if [ -z "$(command -v rclone)" ]; then
    echo "rclone is not installed."
else
    eval "$(rclone completion "${TYPE_OF_SHELL}" -)"
fi

# -----------------------------------------------------------------------------
# Custom environment variables
# -----------------------------------------------------------------------------

export GPG_TTY=$(tty)

export GOPATH="$HOME/.local/share/go"

export XDG_DATA_HOME=$HOME/.local/share
export XDG_CONFIG_HOME=$HOME/.config
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CACHE_HOME=$HOME/.cache

export EDITOR="code --wait"

mkdir -p -v ~/App_cache/
# https://pytorch.org/docs/stable/hub.html#where-are-my-downloaded-models-saved
export TORCH_HOME=~/App_cache/torch_home/

# https://huggingface.co/docs/huggingface_hub/package_reference/environment_variables#hfhome
export HF_HOME=~/App_cache/huggingface_home/

export LC_ALL="en_US.utf8"

export TERM=xterm-256color

export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"

# -----------------------------------------------------------------------------
