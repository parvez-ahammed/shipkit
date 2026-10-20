# Install the secret-hygiene pre-commit hook into a target git repo.
#   pwsh -File install.ps1 -Repo C:\path\to\repo      # defaults to current dir
param([string]$Repo = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
# Ask git for the hooks dir: handles worktrees (.git is a file) and core.hooksPath.
$hooksDir = git -C $Repo rev-parse --path-format=absolute --git-path hooks 2>$null
if ($LASTEXITCODE -ne 0 -or -not $hooksDir) { throw "$Repo is not a git repo" }

$src  = Join-Path $PSScriptRoot "pre-commit"
$dest = Join-Path $hooksDir "pre-commit"
New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null

if (Test-Path $dest) { Copy-Item $dest "$dest.bak" -Force; Write-Host "backed up existing hook -> pre-commit.bak" }
Copy-Item $src $dest -Force
# Git for Windows ignores the exec bit; set it where it matters.
if ($IsLinux -or $IsMacOS) { chmod +x $dest }

Write-Host "installed secret-hygiene pre-commit -> $dest" -ForegroundColor Green
Write-Host "Tip: install gitleaks for best coverage (the hook uses it when present)."
