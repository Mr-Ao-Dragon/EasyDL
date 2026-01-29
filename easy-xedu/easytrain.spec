# PyInstaller spec for EasyTrain launcher
# Run on Windows (in a venv with dependencies installed):
# pyinstaller --noconfirm --onefile easytrain.spec

# Edit paths below if structure differs. This .spec bundles the `EasyTrain/templates` and
# `EasyTrain/static` folders into the executable. On first run the launcher starts
# the Flask server and opens the default browser.

# Note: use this spec on Windows where Python, torch (cpu) and dependencies are installed.

# -*- mode: python ; coding: utf-8 -*-
from PyInstaller.utils.hooks import collect_data_files

block_cipher = None

# Collect non-Python data from the package if needed
datas = []
# Add the templates and static folders (relative to the spec file)
# On Windows add paths like ('EasyTrain\\templates', 'EasyTrain\\templates')
# Using collect_data_files might include too much; we add exact folders instead.

# Helper to add folder (recursively) to datas
import os

def add_folder_to_datas(src_folder, dest_folder):
    for root, dirs, files in os.walk(src_folder):
        for f in files:
            src_file = os.path.join(root, f)
            # compute target folder inside exe
            rel_root = os.path.relpath(root, src_folder)
            if rel_root == '.':
                target_folder = dest_folder
            else:
                target_folder = os.path.join(dest_folder, rel_root)
            datas.append((src_file, target_folder))

# change these if your structure differs
add_folder_to_datas(os.path.join('EasyTrain','templates'), os.path.join('EasyTrain','templates'))
add_folder_to_datas(os.path.join('EasyTrain','static'), os.path.join('EasyTrain','static'))

a = Analysis(
    ['launcher.py'],
    pathex=['.'],
    binaries=[],
    datas=datas,
    hiddenimports=[],
    hookspath=[],
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
)
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)
exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    name='easytrain',
    debug=False,
    strip=False,
    upx=True,
    console=False,
    icon=None,
)
