# Copy every skill in plugins/shipkit/skills into the Claude Code personal skills dir so they go
# live. This repo is the source of truth; ~/.claude/skills is a synced copy.
#
#   pwsh -File sync-skills.ps1            # sync all
#   pwsh -File sync-skills.ps1 -WhatIf    # preview only
#   (macOS / Linux: bash sync-skills.sh)
[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$Dest = (Join-Path $env:USERPROFILE ".claude\skills")
)

$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot "plugins\shipkit\skills"

if (-not (Test-Path $src)) { throw "No skills/ directory found at $src" }
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

$count = 0
Get-ChildItem -Path $src -Directory | ForEach-Object {
  $name   = $_.Name
  $target = Join-Path $Dest $name
  if ($PSCmdlet.ShouldProcess($target, "sync skill '$name'")) {
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }
    Copy-Item -Recurse -Force $_.FullName $target
    # node_modules and packaging output are build artifacts, not skill content.
    Get-ChildItem -Path $target -Recurse -Force -Include node_modules, *.zip, *.rar |
      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "synced $name -> $target" -ForegroundColor Green
  }
  $count++
}
Write-Host "`n$count skill(s) processed. Start a new Claude Code session to pick them up." -ForegroundColor Cyan
