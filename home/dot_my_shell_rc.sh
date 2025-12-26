#!/usr/bin/env bash
# This file is used to store commands to run at creation of login shells 
# agnosticly of which type of shell is being used.

TYPE_OF_SHELL=$(basename "$SHELL")

echo '==================================================================== 🌟'
printf "🔧 Initializing shell configuration for %s %s %s ...\n" "$TYPE_OF_SHELL" "$BASH_VERSION" "$ZSH_VERSION"
echo '==================================================================== 🌟'

prepend_to_path() {
    dir="$1"
    case ":$PATH:" in
        *":$dir:"*) 
            ;;
        *)
            echo "⬆️  Prepending $dir to PATH."
            export PATH="$dir:$PATH"
            ;;
    esac
}

pretty_path() {
    echo "📁 PATH directories:"
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
}

for dir in "$HOME/.local/bin" "$HOME/.local/share/go/bin"; do
    prepend_to_path "$dir"
done

pretty_path

# -----------------------------------------------------------------------------
# Custom command activations
# -----------------------------------------------------------------------------

if [ -z "$(command -v starship)" ]; then
    echo "starship is not installed. ❌"
else
    eval "$(starship init "${TYPE_OF_SHELL}")"
    # completions for starship
    eval "$(starship completions "${TYPE_OF_SHELL}")"
fi

# Atuin - command history manager
# checking that "$HOME/.atuin/bin/" directory exists
if [ ! -d "$HOME/.atuin/bin/" ]; then
    echo "Directory $HOME/.atuin/bin/ does not exist. Please install Atuin. ❌"
else
    . "$HOME/.atuin/bin/env"

    # if type_of_shell is bash, source the preexec script if it exists
    if [ "$TYPE_OF_SHELL" = "bash" ]; then
        if [ -f ~/.bash-preexec.sh ]; then
            source ~/.bash-preexec.sh
        fi
    fi
    eval "$(atuin init --disable-up-arrow "${TYPE_OF_SHELL}")"
    
    eval "$(atuin gen-completions --shell "${TYPE_OF_SHELL}")"
fi

## Broot
# if `/home/lolo/.config/broot/launcher/bash/br` exists, source it
if [ -f "$HOME/.config/broot/launcher/bash/br" ]; then
    # shellcheck source=./.config/broot/launcher/bash/br
    source "$HOME/.config/broot/launcher/bash/br"
else
    echo "Broot launcher script not found at $HOME/.config/broot/launcher/bash/br. ⚠️"
fi

# -----------------------------------------------------------------------------
# Custom shell completions
# -----------------------------------------------------------------------------

# checking that fx is installed
if [ -z "$(command -v fx)" ]; then
    echo "fx is not installed. ❌"
else
    source <(fx --comp "${TYPE_OF_SHELL}")
    export FX_THEME="5"
fi

## UV
# checking that uv is installed
if [ -z "$(command -v uv)" ]; then
    echo "uv is not installed. ❌"
else
    eval "$(uv generate-shell-completion "${TYPE_OF_SHELL}")"
    eval "$(uvx --generate-shell-completion "${TYPE_OF_SHELL}")"
fi

## zoxide 
# checking that zoxide is installed
if [ -z "$(command -v zoxide)" ]; then
    echo "zoxide is not installed. ❌"
else
    eval "$(zoxide init "${TYPE_OF_SHELL}")"
fi

## chezmoi 
# checking that chezmoi is installed
if [ -z "$(command -v chezmoi)" ]; then
    echo "chezmoi is not installed. ❌"
else
    eval "$(chezmoi completion "${TYPE_OF_SHELL}")" 
fi

## gh
# checking that gh is installed
if [ -z "$(command -v gh)" ]; then
    echo "gh is not installed. ❌"
else
    eval "$(gh completion -s "${TYPE_OF_SHELL}")"
    
    # gh copilot convenient aliases
    # Use the subcommand's --help to detect presence; `gh help copilot` may return 0 even when the subcommand isn't available.
    if gh copilot --help &>/dev/null; then
        eval "$(gh copilot alias -- "${TYPE_OF_SHELL}")"
    else
        echo "The 'gh copilot' subcommand does not exist. ⚠️"
    fi

fi

## rclone 
# checking that rclone is installed
if [ -z "$(command -v rclone)" ]; then
    echo "rclone is not installed. ❌"
else
    eval "$(rclone completion "${TYPE_OF_SHELL}" -)"
fi

## Taskfile
if [ -z "$(command -v task)" ]; then
    echo "Taskfile is not installed. ❌"
else
    eval "$(task --completion "${TYPE_OF_SHELL}")"
fi

## doctl - DigitalOcean CLI
if [ -z "$(command -v doctl)" ]; then
    echo "doctl is not installed. ❌" 
else
    source <(doctl completion "${TYPE_OF_SHELL}")
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

# CUDA environment variables
# Ensure that the CUDA toolkit is installed and the paths are correct.
# Adjust the paths below if your CUDA installation is in a different location.
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH



# Function: pretty_env_vars
# Prints a simple table of the custom environment variables set by this script
pretty_env_vars() {
    local -a vars
    vars=(
        "GPG_TTY|GPG TTY device used by GPG"
        "GOPATH|Go workspace directory"
        "XDG_DATA_HOME|XDG data home"
        "XDG_CONFIG_HOME|XDG config home"
        "XDG_STATE_HOME|XDG state home"
        "XDG_CACHE_HOME|XDG cache home"
        "EDITOR|Preferred editor command"
        "TORCH_HOME|Torch cache / hub directory"
        "HF_HOME|Hugging Face cache directory"
        "LC_ALL|Locale setting"
        "TERM|Terminal type"
        "MANPAGER|Manpage pager command"
        "CUDA_HOME|CUDA toolkit root"
        "PATH|Current PATH"
        "LD_LIBRARY_PATH|Dynamic linker library path"
    )

    printf "🔎 %-20s %-60s %s\n" "VARIABLE" "VALUE" "DESCRIPTION"
    printf "🔎 %-20s %-60s %s\n" "--------" "-----" "-----------"

    for entry in "${vars[@]}"; do
        name="${entry%%|*}"
        desc="${entry#*|}"
        # Indirect expansion to get variable value
        val="${!name}"
        if [ -z "$val" ]; then
            val="(not set)"
        fi
        # Shorten long values for readability
        if [ ${#val} -gt 58 ]; then
            display_val="${val:0:55}..."
        else
            display_val="$val"
        fi
        printf "   %-20s %-60s %s\n" "$name" "$display_val" "$desc"
    done
    echo "🔚 End of environment variables table"
}

# Show the custom env vars at shell init (can be commented out if too verbose)
pretty_env_vars

# -----------------------------------------------------------------------------


# FIXME: /home/lolo/.local/share/oracle-cli/lib/python3.10/site-packages/oci_cli/bin/oci_autocomplete.sh:12: command not found: complete

# Replace this single "oracle" line with proper OCI CLI setup
# Setup OCI CLI autocomplete based on shell type
# if [[ -e "/home/lolo/.local/share/oracle-cli/lib/python3.10/site-packages/oci_cli/bin/oci_autocomplete.sh" ]]; then
    # if [ "$TYPE_OF_SHELL" = "bash" ]; then
        # source "/home/lolo/.local/share/oracle-cli/lib/python3.10/site-packages/oci_cli/bin/oci_autocomplete.sh"
    # elif [ "$TYPE_OF_SHELL" = "zsh" ]; then
        # For Zsh, we need to ensure compinit is loaded first
        # autoload -Uz compinit && compinit
        # source "/home/lolo/.local/share/oracle-cli/lib/python3.10/site-packages/oci_cli/bin/oci_autocomplete.sh"
    # else
        # echo "Oracle CLI autocomplete not configured for $TYPE_OF_SHELL"
    # fi
# fi
# 