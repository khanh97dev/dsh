#!/bin/sh
# Install the free OpenCode Zen models plugin (@opencode2dsh/dsh-plugin) into DSH.
#
#   curl -fsSL https://raw.githubusercontent.com/khanh97dev/dsh/main/plugin-opencode2dsh.sh | sh
#   curl -fsSL https://raw.githubusercontent.com/khanh97dev/dsh/main/plugin-opencode2dsh.sh | sh -s -- --desktop-only
#
# DSH Desktop runs its own harness (DSH_HOME), separate from the terminal one (~/.dsh),
# so by default the plugin is installed into BOTH when the desktop home exists.
#
# Options:
#   --desktop-only    install only into DSH Desktop's harness
#   --cli-only        install only into the terminal harness (~/.dsh)
#   --profile <name>  profile to install into (default: web)
#   --package <spec>  package or tarball (default: @opencode2dsh/dsh-plugin)
#   -h, --help        show this help
set -eu

PKG="@opencode2dsh/dsh-plugin"
PROFILE="web"
do_cli=1
do_desktop=1

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --desktop-only) do_cli=0 ;;
    --cli-only)     do_desktop=0 ;;
    --profile)      shift; [ $# -gt 0 ] || die "--profile needs a value"; PROFILE="$1" ;;
    --package)      shift; [ $# -gt 0 ] || die "--package needs a value"; PKG="$1" ;;
    -h|--help)      sed -n '2,16p' "$0" 2>/dev/null | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

have dsh || die "dsh CLI not found. Install it first: npm i -g @deepseek-ai/dsh"

case "$(uname -s)" in
  Darwin*)               desktop_home="$HOME/Library/Application Support/dsh-desktop/harness" ;;
  MINGW*|MSYS*|CYGWIN*)  desktop_home="${APPDATA:-$HOME/AppData/Roaming}/dsh-desktop/harness" ;;
  *)                     desktop_home="${XDG_CONFIG_HOME:-$HOME/.config}/dsh-desktop/harness" ;;
esac

install_into() { # install_into <label> [DSH_HOME]
  label="$1"
  log "installing $PKG into $label (profile: $PROFILE)"
  if [ $# -ge 2 ]; then
    DSH_HOME="$2" dsh plugin --profile "$PROFILE" add "$PKG"
  else
    dsh plugin --profile "$PROFILE" add "$PKG"
  fi
}

installed=0
if [ "$do_cli" = 1 ]; then
  install_into "terminal harness"
  installed=1
fi
if [ "$do_desktop" = 1 ]; then
  if [ -d "$desktop_home" ]; then
    install_into "DSH Desktop ($desktop_home)" "$desktop_home"
    installed=1
  elif [ "$do_cli" = 0 ]; then
    die "DSH Desktop harness not found at: $desktop_home (open DSH Desktop once, then retry)"
  else
    warn "DSH Desktop harness not found, skipped: $desktop_home"
  fi
fi

[ "$installed" = 1 ] || die "nothing installed"
log "done. Restart DSH Desktop / 'dsh web', then pick a model from the opencode2dsh group."
