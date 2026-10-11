#!/bin/sh
# DSH installer: DeepSeek Harness CLI (@deepseek-ai/dsh) + DSH Desktop.
#
#   curl -fsSL https://raw.githubusercontent.com/khanh97dev/dsh/main/install.sh | sh
#   curl -fsSL https://raw.githubusercontent.com/khanh97dev/dsh/main/install.sh | sh -s -- --cli-only
#
# Options:
#   --cli-only        install only the dsh CLI
#   --desktop-only    install only DSH Desktop
#   --plugin          also add @opencode2dsh/dsh-plugin (profile: web)
#   --version <tag>   desktop release tag (default: latest)
#   -h, --help        show this help
#
# Env: DSH_DESKTOP_REPO (default liguobao/dsh-desktop), DSH_INSTALL_DIR (Linux AppImage dir)
set -eu

DESKTOP_REPO="${DSH_DESKTOP_REPO:-liguobao/dsh-desktop}"
CLI_PKG="@deepseek-ai/dsh"
PLUGIN_PKG="@opencode2dsh/dsh-plugin"
NODE_MIN=22

want_cli=1
want_desktop=1
want_plugin=0
version=""

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() { sed -n '2,15p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0; }

while [ $# -gt 0 ]; do
  case "$1" in
    --cli-only)     want_desktop=0 ;;
    --desktop-only) want_cli=0 ;;
    --plugin)       want_plugin=1 ;;
    --version)      shift; [ $# -gt 0 ] || die "--version needs a value"; version="$1" ;;
    -h|--help)      usage ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

# ---- platform detection ----
case "$(uname -s)" in
  Linux*)                os=linux ;;
  Darwin*)               os=macos ;;
  MINGW*|MSYS*|CYGWIN*)  os=windows ;;
  *) die "unsupported OS: $(uname -s)" ;;
esac
case "$(uname -m)" in
  x86_64|amd64)  arch=x64 ;;
  arm64|aarch64) arch=arm64 ;;
  *) die "unsupported architecture: $(uname -m)" ;;
esac
log "platform: $os-$arch"

fetch() { # fetch <url> <out>
  if have curl; then curl -fL --progress-bar -o "$2" "$1"
  elif have wget; then wget -O "$2" "$1"
  else die "curl or wget is required"; fi
}

# ---- CLI ----
install_cli() {
  have node || die "Node.js >= $NODE_MIN is required (https://nodejs.org)"
  have npm  || die "npm is required"
  major="$(node -p 'process.versions.node.split(".")[0]')"
  [ "$major" -ge "$NODE_MIN" ] || die "Node.js >= $NODE_MIN required, found $(node -v)"
  log "installing $CLI_PKG"
  npm install -g "$CLI_PKG" || die "npm install failed (try with sudo, or set an npm prefix in your home dir)"
  have dsh || warn "dsh installed but not on PATH; add \"$(npm prefix -g)/bin\" to PATH"
  have dsh && log "dsh $(dsh --version)"
}

install_plugin() {
  have dsh || die "dsh CLI not found; run without --desktop-only first"
  log "adding $PLUGIN_PKG (profile: web)"
  dsh plugin --profile web add "$PLUGIN_PKG"
}

# ---- Desktop ----
resolve_tag() {
  if [ -n "$version" ]; then printf '%s' "$version"; return; fi
  api="https://api.github.com/repos/$DESKTOP_REPO/releases/latest"
  if have curl; then body="$(curl -fsSL "$api")"; else body="$(wget -qO- "$api")"; fi
  printf '%s' "$body" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1
}

install_desktop() {
  tag="$(resolve_tag)"
  [ -n "$tag" ] || die "could not resolve latest release of $DESKTOP_REPO"
  log "DSH Desktop $tag"
  base="https://github.com/$DESKTOP_REPO/releases/download/$tag"
  tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

  case "$os-$arch" in
    linux-x64)
      f="DSH-Desktop-$tag-linux-x64.AppImage"
      dir="${DSH_INSTALL_DIR:-$HOME/.local/share/dsh-desktop}"
      mkdir -p "$dir" "$HOME/.local/bin" "$HOME/.local/share/applications"
      fetch "$base/$f" "$tmp/$f"
      install -m 755 "$tmp/$f" "$dir/DSH-Desktop.AppImage"
      ln -sf "$dir/DSH-Desktop.AppImage" "$HOME/.local/bin/dsh-desktop"
      cat > "$HOME/.local/share/applications/dsh-desktop.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=DSH Desktop
Exec=$dir/DSH-Desktop.AppImage --no-sandbox %U
Terminal=false
Categories=Development;
EOF
      log "installed to $dir (run: dsh-desktop)"
      ;;
    macos-arm64|macos-x64)
      f="DSH-Desktop-$tag-macos-$arch.dmg"
      fetch "$base/$f" "$tmp/$f"
      mnt="$tmp/mnt"; mkdir -p "$mnt"
      hdiutil attach "$tmp/$f" -nobrowse -quiet -mountpoint "$mnt"
      app="$(find "$mnt" -maxdepth 1 -name '*.app' | head -n1)"
      [ -n "$app" ] || { hdiutil detach "$mnt" -quiet; die "no .app found in dmg"; }
      rm -rf "/Applications/$(basename "$app")"
      cp -R "$app" /Applications/
      hdiutil detach "$mnt" -quiet
      xattr -dr com.apple.quarantine "/Applications/$(basename "$app")" 2>/dev/null || true
      log "installed /Applications/$(basename "$app")"
      ;;
    windows-x64)
      f="DSH-Desktop-$tag-windows-x64-setup.exe"
      fetch "$base/$f" "$tmp/$f"
      log "running installer"
      "$tmp/$f"
      ;;
    *) die "no desktop build for $os-$arch" ;;
  esac
}

[ "$want_cli" = 1 ]     && install_cli
[ "$want_plugin" = 1 ]  && install_plugin
[ "$want_desktop" = 1 ] && install_desktop
log "done"
