#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/.config"
DEST="$HOME/.config"
BACKUP="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
WALLPAPER_SRC="$SCRIPT_DIR/wallpapers/les_bordovye_osen.jpg"
WALLPAPER_DEST="$HOME/Pictures/wallpapers/les_bordovye_osen.jpg"

if [ "$(id -u)" -eq 0 ]; then
  printf 'Run this script as your user, not as root.\n' >&2
  exit 1
fi

if [ ! -d "$SRC" ]; then
  printf 'Missing %s. Run the script from the repository root.\n' "$SRC" >&2
  exit 1
fi

mkdir -p "$DEST"
shopt -s nullglob dotglob

for src in "$SRC"/*; do
  name="$(basename -- "$src")"
  [ "$name" = "librewolf" ] && continue

  dest="$DEST/$name"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$BACKUP"
    mv -- "$dest" "$BACKUP/"
    printf 'Backed up %s\n' "$dest"
  fi

  cp -a -- "$src" "$DEST/"
  printf 'Installed %s\n' "$dest"
done

# LibreWolf: only add user.js to existing profiles, never replace the profile itself.
if [ -f "$SRC/librewolf/user.js" ]; then
  lw_root="$DEST/librewolf"
  if [ -d "$lw_root" ]; then
    found=0
    while IFS= read -r -d '' prefs; do
      profile="${prefs%/*}"
      found=1
      if [ -f "$profile/user.js" ]; then
        mkdir -p "$BACKUP/librewolf"
        cp -a -- "$profile/user.js" "$BACKUP/librewolf/$(basename -- "$profile")-user.js"
      fi
      cp -a -- "$SRC/librewolf/user.js" "$profile/user.js"
      printf 'Installed LibreWolf user.js in %s\n' "$profile"
    done < <(find "$lw_root" -type f -name prefs.js -print0 2>/dev/null)

    if [ "$found" -eq 0 ]; then
      if [ -f "$lw_root/user.js" ]; then
        mkdir -p "$BACKUP/librewolf"
        cp -a -- "$lw_root/user.js" "$BACKUP/librewolf/user.js"
      fi
      cp -a -- "$SRC/librewolf/user.js" "$lw_root/user.js"
      printf 'No LibreWolf profile found; copied user.js to %s\n' "$lw_root/user.js"
    fi
  else
    mkdir -p "$lw_root"
    cp -a -- "$SRC/librewolf/user.js" "$lw_root/user.js"
    printf 'LibreWolf not found; copied user.js to %s\n' "$lw_root/user.js"
  fi
fi

# Make the copied configs portable instead of pointing at the original user's home.
home_escaped="$(printf '%s' "$HOME" | sed 's/[\/&|\\]/\\&/g')"
while IFS= read -r file; do
  sed -i "s|/home/artik|$home_escaped|g" "$file"
done < <(
  grep -rlI -- '/home/artik' \
    "$DEST/hypr" "$DEST/waybar" "$DEST/mako" "$DEST/rofi" "$DEST/wofi" \
    "$DEST/nwg-dock-hyprland" "$DEST/gtk-3.0" "$DEST/gtk-4.0" \
    "$DEST/Kvantum" "$DEST/qt5ct" "$DEST/qt6ct" "$DEST/alacritty" \
    "$DEST/kdeglobals" 2>/dev/null || true
)

if [ -d "$BACKUP" ]; then
  printf '\nBackup: %s\n' "$BACKUP"
else
  rmdir -- "$BACKUP" 2>/dev/null || true
fi

if [ -f "$WALLPAPER_SRC" ]; then
  mkdir -p "$(dirname -- "$WALLPAPER_DEST")"
  if [ -f "$WALLPAPER_DEST" ]; then
    mkdir -p "$BACKUP/Pictures/wallpapers"
    cp -a -- "$WALLPAPER_DEST" "$BACKUP/Pictures/wallpapers/"
    printf 'Backed up %s\n' "$WALLPAPER_DEST"
  fi
  cp -a -- "$WALLPAPER_SRC" "$WALLPAPER_DEST"
  printf 'Installed wallpaper %s\n' "$WALLPAPER_DEST"
else
  printf 'Warning: wallpaper not found in repo: %s\n' "$WALLPAPER_SRC"
fi

printf '\nDone. Reload with: hyprctl reload\n'
printf 'Restart Waybar with: killall waybar; waybar &\n'
