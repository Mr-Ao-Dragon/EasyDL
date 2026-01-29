# PowerShell script to package EasyTrain on Windows
# Usage: Open PowerShell as Administrator (or a normal user if rights are ok) and run:
#   .\windows_package.ps1 -VenvPath .venv -TorchIndex https://download.pytorch.org/whl/cpu

param(
    [string]$VenvPath = ".venv",
    [string]$Python = "python",
    [string]$TorchIndex = "https://download.pytorch.org/whl/cpu",
    [string]$TorchVersion = "",
    [string]$SpecFile = "easytrain.spec",
    [string]$Launcher = "launcher.py"
)

Write-Host "Packaging EasyTrain for Windows..."

# Create venv
& $Python -m venv $VenvPath
$Activate = Join-Path $VenvPath "Scripts\Activate.ps1"
if (-Not (Test-Path $Activate)) { Write-Error "Failed to create venv or cannot find Activate script"; exit 1 }

# Activate venv for the rest of the script
Write-Host "Activating venv..."
. $Activate

Write-Host "Upgrading pip, setuptools, wheel..."
python -m pip install --upgrade pip setuptools wheel

# Install CPU-only torch from the provided index
if ($TorchVersion -ne "") {
    Write-Host "Installing torch $TorchVersion from $TorchIndex"
    python -m pip install --index-url $TorchIndex "torch==$TorchVersion"
} else {
    Write-Host "Installing torch (latest CPU build) from $TorchIndex"
    python -m pip install --index-url $TorchIndex torch torchvision torchaudio
}

# Install project dependencies
Write-Host "Installing project dependencies (editable)"
pip install -e .

# Install pyinstaller
Write-Host "Installing PyInstaller"
python -m pip install pyinstaller

# Run pyinstaller with the provided spec (or fallback to launcher.py)
if (Test-Path $SpecFile) {
    Write-Host "Running pyinstaller using spec: $SpecFile"
    pyinstaller --noconfirm --onefile $SpecFile
} else {
    Write-Host "Spec file not found; using launcher.py default packaging"
    pyinstaller --noconfirm --onefile --name easytrain $Launcher --add-data "EasyTrain\templates;EasyTrain\templates" --add-data "EasyTrain\static;EasyTrain\static"
}

Write-Host "Packaging done. Check the dist folder for easytrain.exe"

# Deactivate venv (PowerShell)
Write-Host "Done. You may deactivate the venv by closing this shell or running 'deactivate' if available.'"
