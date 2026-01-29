#!/usr/bin/env bash
set -euo pipefail

# linux_package.sh
# Simple packaging helper for Linux using PyInstaller.
# Usage: ./linux_package.sh [--venv .venv_pkg] [--no-install-reqs]
# Run from the easy-xedu directory.

VENV_PATH=.venv_pkg
INSTALL_REQS=1
PYTHON=${PYTHON:-python3}
SPEC=easytrain.spec
LAUNCHER=launcher.py

while [[ $# -gt 0 ]]; do
  case "$1" in
    --venv)
      VENV_PATH="$2"; shift 2;;
    --no-install-reqs)
      INSTALL_REQS=0; shift;;
    --python)
      PYTHON="$2"; shift 2;;
    --spec)
      SPEC="$2"; shift 2;;
    --launcher)
      LAUNCHER="$2"; shift 2;;
    -h|--help)
      echo "Usage: $0 [--venv .venv_pkg] [--no-install-reqs] [--python python3]"; exit 0;;
    *)
      echo "Unknown arg: $1"; exit 1;;
  esac
done

echo "Packaging EasyTrain on Linux"
echo "Venv: $VENV_PATH, Python: $PYTHON, Install reqs: $INSTALL_REQS"

# Create venv
if [[ ! -d "$VENV_PATH" ]]; then
  echo "Creating venv at $VENV_PATH"
  $PYTHON -m venv "$VENV_PATH"
fi

# Activate
# shellcheck source=/dev/null
source "$VENV_PATH/bin/activate"

echo "Upgrading pip, setuptools, wheel"
python -m pip install --upgrade pip setuptools wheel

if [[ $INSTALL_REQS -eq 1 ]]; then
  if [[ -f requirements.txt ]]; then
    echo "Installing requirements.txt (may be slow and platform-specific)"
    # attempt install but continue if some platform-specific packages fail
    python -m pip install -r requirements.txt || echo "Some requirements failed to install; continuing"
  else
    echo "No requirements.txt found, skipping";
  fi
fi

echo "Installing PyInstaller"
python -m pip install --upgrade pyinstaller

# Build command
ADD_DATA_ARGS=("EasyTrain/templates:EasyTrain/templates" "EasyTrain/static:EasyTrain/static")
ADD_FLAGS=()
for d in "${ADD_DATA_ARGS[@]}"; do
  ADD_FLAGS+=(--add-data "$d")
done

# If spec file exists prefer using spec; else use launcher with add-data flags
if [[ -f "$SPEC" ]]; then
  echo "Using spec file: $SPEC"
  # When providing a spec file, don't pass --onefile/--onedir options to pyinstaller
  pyinstaller --noconfirm "$SPEC"
else
  echo "Packing $LAUNCHER with PyInstaller and including templates/static"
  # shellcheck disable=SC2086
  pyinstaller --noconfirm --onefile --name easytrain "$LAUNCHER" ${ADD_FLAGS[@]}
fi

echo "Build finished. Executable in dist/"

# Quick smoke-test: run the generated binary with --no-browser and check port
EXE=dist/easytrain
if [[ -x "$EXE" ]]; then
  echo "Found executable $EXE. Running smoke-test (background)"
  "$EXE" --workfolder . --no-browser &
  PID=$!
  echo "Started PID $PID"
  sleep 2
  if ss -ltnp | grep -q ":5000\b"; then
    echo "Server listening on port 5000"
    curl -s -I http://127.0.0.1:5000/ | sed -n '1,200p'
  else
    echo "Server did not start or is not listening on 5000"
    tail -n 200 easytrain.log || true
  fi
  echo "Stopping test PID $PID"
  kill "$PID" || true
else
  echo "Executable not found in dist/ (build may have failed)"
fi

# Deactivate
deactivate || true

echo "Done"
