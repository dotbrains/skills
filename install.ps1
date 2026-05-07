[CmdletBinding()]
param(
    [string]$Repo,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$SkillsArgs
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not $Repo) {
    $Repo = if ($env:DOTBRAINS_SKILLS_REPO) {
        $env:DOTBRAINS_SKILLS_REPO
    } elseif ($env:SKILLS_REPO) {
        $env:SKILLS_REPO
    } else {
        'dotbrains/skills'
    }
}

function Fail([string]$Message) {
    throw $Message
}

function Get-RequiredCommand([string]$Name) {
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $command) {
        Fail("$Name is required but not installed.")
    }
    return $command
}

function Assert-NodeVersion {
    $majorVersion = [int](& node -p "process.versions.node.split('.')[0]")
    if ($LASTEXITCODE -ne 0 -or $majorVersion -lt 18) {
        Fail('Node.js 18 or newer is required.')
    }
}

Get-RequiredCommand 'node' | Out-Null
Get-RequiredCommand 'npx' | Out-Null
Assert-NodeVersion

Write-Host "Installing skills from $Repo..."
& npx --yes skills@latest add $Repo @SkillsArgs
if ($LASTEXITCODE -ne 0) {
    Fail('skills install failed.')
}

Write-Host ''
Write-Host 'Done.'
