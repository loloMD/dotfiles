#!/bin/sh
# Bootstrap installer for chezmoi, fully POSIX-compliant ✨

# Exit on error and unset vars; enable pipefail if supported
set -eu
(set -o pipefail) 2>/dev/null && set -o pipefail

echo "🔍 Checking if chezmoi is installed..."

# Ensure chezmoi is installed
if ! command -v chezmoi >/dev/null 2>&1; then
    echo "⚠️  chezmoi not found. Installing it now..."
    bin_dir="$HOME/.local/bin"
    chezmoi="$bin_dir/chezmoi"

    if command -v curl >/dev/null 2>&1; then
        echo "📥 Downloading chezmoi with curl..."
        sh -c "$(curl -fsSL https://git.io/chezmoi)" -- -b "$bin_dir"
    elif command -v wget >/dev/null 2>&1; then
        echo "📥 Downloading chezmoi with wget..."
        sh -c "$(wget -qO- https://git.io/chezmoi)" -- -b "$bin_dir"
    else
        echo "❌ To install chezmoi, you must have curl or wget installed." >&2
        exit 1
    fi

    # If bin_dir not in PATH, warn but still use absolute path
    case ":$PATH:" in
        *":$bin_dir:"*) echo "✅ Installed chezmoi into $bin_dir (in PATH)" ;;
        *) echo "⚠️  Installed chezmoi into $bin_dir, but it's not in your PATH."
           echo "   Using $chezmoi directly." ;;
    esac
else
    echo "✅ chezmoi is already installed."
    chezmoi=chezmoi
fi

# Resolve script's directory (follows symlinks)
script_dir="$(cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P)"
echo "📂 Script directory resolved to: $script_dir"

# Show resolved .chezmoi.toml.tmpl content
# Define ANSI color escapes safely
cyan=$(printf '\033[36m')
green=$(printf '\033[32m')
yellow=$(printf '\033[33m')
reset=$(printf '\033[0m')

echo ""
echo "📑 Preview of your chezmoi configuration template (with basic colors):"
echo "---------------------------------------------------------------"

"$chezmoi" execute-template < "${script_dir}/home/.chezmoi.toml.tmpl" \
  | sed -E \
    -e "s/^(\[[^]]+\])/${cyan}\1${reset}/" \
    -e "s/^([A-Za-z0-9_.-]+\s*=)/${green}\1${reset}/" \
    -e "s/=\"([^\"]*)\"/=\"${yellow}\1${reset}\"/g"

echo "\n---------------------------------------------------------------"
echo "⚠️  Please validate the [data] section above, as it will impact installation."
echo ""

# Ask for confirmation (portable way)
printf "❓ Do you want to continue with the installation? (y/N): "
read answer
case "$answer" in
    [yY][eE][sS]|[yY])
        echo "🚀 Continuing with installation..."
        ;;
    *)
        echo "🛑 Installation aborted by user."
        exit 0
        ;;
esac

# Replace current process with chezmoi init
echo "⚙️  Running chezmoi init with source: $script_dir ..."
exec "$chezmoi" init --apply --source="$script_dir"
