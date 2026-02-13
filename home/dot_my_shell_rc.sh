#!/usr/bin/env bash
# This file is sourced by interactive shells (bash or zsh).

# Prevent double-sourcing
if [ -n "${__MY_SHELL_RC_LOADED-}" ]; then
    return 0 2>/dev/null || exit 0
fi
__MY_SHELL_RC_LOADED=1

my_shell_rc_running_shell() {
    if [ -n "${BASH_VERSION-}" ]; then
        echo "bash"
        return 0
    fi
    if [ -n "${ZSH_VERSION-}" ]; then
        echo "zsh"
        return 0
    fi
    basename "${SHELL:-sh}"
}

TYPE_OF_SHELL="$(my_shell_rc_running_shell)"

my_shell_rc_is_interactive() {
    case $- in
        *i*) return 0 ;;
        *) return 1 ;;
    esac
}

: "${MY_SHELL_RC_VERBOSE:=1}"

my_shell_rc_log() {
    if [ "${MY_SHELL_RC_VERBOSE}" = "1" ]; then
        printf "%s\n" "$*"
    fi
}

if my_shell_rc_is_interactive && [ "${MY_SHELL_RC_VERBOSE}" = "1" ]; then
    shell_version=""
    if [ "$TYPE_OF_SHELL" = "bash" ]; then
        shell_version="${BASH_VERSION-}"
    elif [ "$TYPE_OF_SHELL" = "zsh" ]; then
        shell_version="${ZSH_VERSION-}"
    fi

    echo '==================================================================== 🌟'
    if [ -n "${shell_version}" ]; then
        printf "🔧 Initializing shell configuration for %s %s ...\n" "$TYPE_OF_SHELL" "$shell_version"
    else
        printf "🔧 Initializing shell configuration for %s ...\n" "$TYPE_OF_SHELL"
    fi
    echo '==================================================================== 🌟'
fi

prepend_to_path() {
    local dir
    dir="$1"
    [ -n "$dir" ] || return 0
    case ":$PATH:" in
        *":$dir:"*) 
            ;;
        *)
            my_shell_rc_log "⬆️  Prepending $dir to PATH."
            PATH="$dir:$PATH"
            export PATH
            ;;
    esac
}

pretty_path() {
    my_shell_rc_is_interactive || return 0
    [ "${MY_SHELL_RC_VERBOSE}" = "1" ] || return 0

    echo "📁 PATH directories:"
    printf "%-2s %-70s %12s\n" "" "PATH" "EXECUTABLES"
    printf "%-2s %-70s %12s\n" "" "----" "-----------"

    local -a dirs
    if [ "$TYPE_OF_SHELL" = "zsh" ]; then
        # In zsh, word-splitting on IFS doesn't happen by default; use the `path` array.
        # shellcheck disable=SC2154
        dirs=("${path[@]}")
    else
        IFS=':' read -r -a dirs <<< "${PATH-}"
    fi

    local dir dir_status file_count
    for dir in "${dirs[@]}"; do
        [ -n "$dir" ] || dir='.'

        if [ -d "$dir" ]; then
            dir_status="✅"
            file_count=$(find "$dir" -maxdepth 1 -type f -perm -111 2>/dev/null | wc -l | tr -d ' ')
        else
            dir_status="❌"
            file_count="-"
        fi

        printf "%-2s %-70s %12s\n" "$dir_status" "$dir" "$file_count"
    done
}

pretty_env_vars() {
    my_shell_rc_is_interactive || return 0
    [ "${MY_SHELL_RC_VERBOSE}" = "1" ] || return 0

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
        "BUN_INSTALL|Bun installation directory"
        "NVM_DIR|NVM directory"
    )

    printf "🔎 %-20s %-60s %s\n" "VARIABLE" "VALUE" "DESCRIPTION"
    printf "🔎 %-20s %-60s %s\n" "--------" "-----" "-----------"

    local entry name desc val display_val
    for entry in "${vars[@]}"; do
        name="${entry%%|*}"
        desc="${entry#*|}"
        # Portable indirect expansion
        eval "val=\${${name}-}"
        if [ -z "${val-}" ]; then
            val="(not set)"
        fi
        display_val=$(printf "%.55s" "$val")
        if [ "${#val}" -gt 55 ]; then
            display_val="${display_val}..."
        fi
        printf "   %-20s %-60s %s\n" "$name" "$display_val" "$desc"
    done
    echo "🔚 End of environment variables table"
}

my_shell_rc_env_init() {
    # -------------------------------------------------------------------------
    # Custom environment variables
    # -------------------------------------------------------------------------

    export GOPATH="$HOME/.local/share/go"

    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_CONFIG_HOME="$HOME/.config"
    export XDG_STATE_HOME="$HOME/.local/state"
    export XDG_CACHE_HOME="$HOME/.cache"

    export EDITOR="code --wait"

    # Only set GPG_TTY when a TTY is available
    if command -v tty >/dev/null 2>&1; then
        GPG_TTY="$(tty 2>/dev/null)"
        export GPG_TTY
    fi

    mkdir -p "$HOME/App_cache" 2>/dev/null
    export TORCH_HOME="$HOME/App_cache/torch_home"
    export HF_HOME="$HOME/App_cache/huggingface_home"

    export LC_ALL="en_US.utf8"
    export TERM=xterm-256color

    export MANPAGER="sh -c 'sed -u -e \"s/\\x1B\\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"

    # CUDA environment variables
    export CUDA_HOME=/usr/local/cuda

    # -------------------------------------------------------------------------
    # PATH setup
    # -------------------------------------------------------------------------

    prepend_to_path "$HOME/.local/bin"
    prepend_to_path "$HOME/.local/share/go/bin"
    prepend_to_path "$CUDA_HOME/bin"
    prepend_to_path "$HOME/.koyeb/bin"

    # bun
    export BUN_INSTALL="$HOME/.bun"
    prepend_to_path "$BUN_INSTALL/bin"

    # LD_LIBRARY_PATH (avoid adding duplicates)
    if [ -d "$CUDA_HOME/lib64" ]; then
        case ":${LD_LIBRARY_PATH-}:" in
            *":$CUDA_HOME/lib64:"*) ;;
            *)
                LD_LIBRARY_PATH="$CUDA_HOME/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
                export LD_LIBRARY_PATH
                ;;
        esac
    fi

    pretty_path

    # -------------------------------------------------------------------------
    # Tool environment hooks (shared)
    # -------------------------------------------------------------------------

    # Rust
    if [ -f "$HOME/.cargo/env" ]; then
        # shellcheck disable=SC1090
        . "$HOME/.cargo/env"
    fi

    # Deno
    if [ -f "$HOME/.deno/env" ]; then
        # shellcheck disable=SC1090
        . "$HOME/.deno/env"
    elif [ -f "/home/lolo/.deno/env" ]; then
        # shellcheck disable=SC1091
        . "/home/lolo/.deno/env"
    fi

    # NVM
    export NVM_DIR="$HOME/.config/nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck disable=SC1090
        . "$NVM_DIR/nvm.sh"
    fi
    if [ "$TYPE_OF_SHELL" = "bash" ] && [ -s "$NVM_DIR/bash_completion" ]; then
        # shellcheck disable=SC1090
        . "$NVM_DIR/bash_completion"
    fi

    # Kiro shell integration
    if [ "${TERM_PROGRAM-}" = "kiro" ] && command -v kiro >/dev/null 2>&1; then
        if [ "$TYPE_OF_SHELL" = "bash" ]; then
            # shellcheck disable=SC1090
            . "$(kiro --locate-shell-integration-path bash)"
        elif [ "$TYPE_OF_SHELL" = "zsh" ]; then
            # shellcheck disable=SC1090
            . "$(kiro --locate-shell-integration-path zsh)"
        fi
    fi

    # bun completions are zsh-specific
    if [ "$TYPE_OF_SHELL" = "zsh" ] && [ -s "/home/lolo/.bun/_bun" ]; then
        # shellcheck disable=SC1091
        source "/home/lolo/.bun/_bun"
    fi
}

my_shell_rc_source_if_exists() {
    local file
    file="$1"
    if [ -f "$file" ]; then
        # shellcheck disable=SC1090
        source "$file"
    else
        my_shell_rc_log "File $file not found."
    fi
}

my_shell_rc_env_init

# Source aliases for both shells
my_shell_rc_source_if_exists "$HOME/.my_aliases.sh"

pretty_env_vars

my_shell_rc_deferred_init() {
    # -------------------------------------------------------------------------
    # Custom command activations + completions
    #
    # For zsh, call this after compinit.
    # For bash, this can run immediately (bash-completion is loaded in .bashrc).
    # -------------------------------------------------------------------------

    # starship
    if command -v starship >/dev/null 2>&1; then
        eval "$(starship init "${TYPE_OF_SHELL}")"
        eval "$(starship completions "${TYPE_OF_SHELL}")"
    else
        echo "starship is not installed. ❌"
    fi

    # Atuin
    if [ -d "$HOME/.atuin/bin/" ]; then
        # shellcheck disable=SC1090
        . "$HOME/.atuin/bin/env"

        if [ "$TYPE_OF_SHELL" = "bash" ] && [ -f "$HOME/.bash-preexec.sh" ]; then
            # shellcheck disable=SC1090
            source "$HOME/.bash-preexec.sh"
        fi

        eval "$(atuin init --disable-up-arrow "${TYPE_OF_SHELL}")"
        eval "$(atuin gen-completions --shell "${TYPE_OF_SHELL}")"
    else
        echo "Directory $HOME/.atuin/bin/ does not exist. Please install Atuin. ❌"
    fi

    # broot launcher (works in both bash and zsh)
    if [ -f "$HOME/.config/broot/launcher/bash/br" ]; then
        # shellcheck disable=SC1090
        source "$HOME/.config/broot/launcher/bash/br"
    else
        echo "Broot launcher script not found at $HOME/.config/broot/launcher/bash/br. ⚠️"
    fi

    # fx
    if command -v fx >/dev/null 2>&1; then
        # shellcheck disable=SC1090
        source <(fx --comp "${TYPE_OF_SHELL}")
        export FX_THEME="5"
    else
        echo "fx is not installed. ❌"
    fi

    # uv
    if command -v uv >/dev/null 2>&1; then
        eval "$(uv generate-shell-completion "${TYPE_OF_SHELL}")"
        if command -v uvx >/dev/null 2>&1; then
            eval "$(uvx --generate-shell-completion "${TYPE_OF_SHELL}")"
        fi
    else
        echo "uv is not installed. ❌"
    fi

    # zoxide
    if command -v zoxide >/dev/null 2>&1; then
        eval "$(zoxide init "${TYPE_OF_SHELL}")"
    else
        echo "zoxide is not installed. ❌"
    fi

    # chezmoi
    if command -v chezmoi >/dev/null 2>&1; then
        eval "$(chezmoi completion "${TYPE_OF_SHELL}")"
    else
        echo "chezmoi is not installed. ❌"
    fi

    # gh
    if command -v gh >/dev/null 2>&1; then
        eval "$(gh completion -s "${TYPE_OF_SHELL}")"

        if gh copilot --help &>/dev/null; then
            gh_copilot_aliases=""
            if gh_copilot_aliases="$(gh copilot alias -- "${TYPE_OF_SHELL}" 2>/dev/null)" && [ -n "${gh_copilot_aliases}" ]; then
                eval "${gh_copilot_aliases}"
            else
                my_shell_rc_log "Skipping gh copilot aliases (command failed or empty output)."
            fi
            unset gh_copilot_aliases
        else
            my_shell_rc_log "The 'gh copilot' subcommand does not exist. ⚠️"
        fi
    else
        echo "gh is not installed. ❌"
    fi

    # rclone
    if command -v rclone >/dev/null 2>&1; then
        eval "$(rclone completion "${TYPE_OF_SHELL}" -)"
    else
        echo "rclone is not installed. ❌"
    fi

    # task
    if command -v task >/dev/null 2>&1; then
        eval "$(task --completion "${TYPE_OF_SHELL}")"
    else
        echo "Taskfile is not installed. ❌"
    fi

    # doctl
    if command -v doctl >/dev/null 2>&1; then
        # shellcheck disable=SC1090
        source <(doctl completion "${TYPE_OF_SHELL}")
    else
        echo "doctl is not installed. ❌"
    fi

    # aws
    if command -v aws >/dev/null 2>&1; then
        if [ "$TYPE_OF_SHELL" = "bash" ]; then
            if command -v complete >/dev/null 2>&1; then
                complete -C '/usr/local/bin/aws_completer' aws
            fi
        elif [ "$TYPE_OF_SHELL" = "zsh" ]; then
            autoload -Uz +X bashcompinit && bashcompinit
            if command -v complete >/dev/null 2>&1; then
                complete -C '/usr/local/bin/aws_completer' aws
            fi
        fi
    else
        echo "awscli is not installed."
    fi
}

if [ "$TYPE_OF_SHELL" = "bash" ]; then
    my_shell_rc_deferred_init
fi


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