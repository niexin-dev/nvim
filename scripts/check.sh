#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

lua_files=("init.lua")
while IFS= read -r file; do
  lua_files+=("$file")
done < <(find lua -type f -name '*.lua' | sort)

if command -v luac >/dev/null 2>&1; then
  echo "[check] luac -p"
  luac -p "${lua_files[@]}"
else
  echo "[check] luac not found, skipping Lua syntax check" >&2
fi

echo "[check] nvim --headless"
nvim --headless '+qa'

echo "[check] ok"
