<#
.SYNOPSIS
Validates skills in this repository and links them into the skills folder of
every supported agent installed on this machine.

.DESCRIPTION
On Windows:
  Claude Code         %USERPROFILE%\.claude\skills   when the claude CLI or %USERPROFILE%\.claude exists
  GitHub Copilot      %USERPROFILE%\.copilot\skills  when the copilot CLI, %USERPROFILE%\.copilot or the VS Code extension exists
  Devin for Terminal  %APPDATA%\devin\skills         when the devin CLI or %APPDATA%\devin exists

On Windows the links are directory junctions, which don't need administrator
rights or Developer Mode. With PowerShell 7 on macOS or Linux, the script uses
symbolic links and the same folders as register.sh.

.EXAMPLE
.\register.ps1 java-unit-tests

.EXAMPLE
.\register.ps1 -All
#>
[CmdletBinding()]
param(
    [switch]$All,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Names
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$OnWindows = ($PSVersionTable.PSEdition -eq 'Desktop') -or $IsWindows
$SkillsDir = (Resolve-Path (Join-Path $PSScriptRoot (Join-Path '..' '..'))).Path
$UserHome = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }

function Write-Failure([string]$Name, [string]$Message) {
    [Console]::Error.WriteLine("ERROR [$Name]: $Message")
}

function Get-FrontmatterValue([string]$File, [string]$Key) {
    $lines = @(Get-Content -LiteralPath $File -Encoding UTF8)
    if ($lines.Count -eq 0 -or $lines[0] -ne '---') { return $null }
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq '---') { return $null }
        if ($lines[$i].StartsWith("${Key}: ")) { return $lines[$i].Substring($Key.Length + 2) }
    }
    return $null
}

function Test-Quoted([string]$Value) {
    return $Value -match '^(".*"|''.*'')$'
}

function Test-Skill([string]$Name) {
    $dir = Join-Path $SkillsDir $Name
    $file = Join-Path $dir 'SKILL.md'
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { Write-Failure $Name "folder $dir not found"; return $false }
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { Write-Failure $Name 'SKILL.md not found'; return $false }
    if ($Name -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$') { Write-Failure $Name 'folder name must be lowercase letters, digits and hyphens'; return $false }

    $frontmatterName = Get-FrontmatterValue $file 'name'
    $description = Get-FrontmatterValue $file 'description'
    if ($frontmatterName -cne $Name) { Write-Failure $Name "frontmatter name '$frontmatterName' must match the folder name"; return $false }
    if (-not $description) { Write-Failure $Name 'frontmatter description is missing or not on one line'; return $false }
    if (-not (Test-Quoted $description) -and $description.Contains(': ')) {
        Write-Failure $Name "description contains ': ', which is invalid YAML. Reword it or wrap it in double quotes"
        return $false
    }
    return $true
}

function Test-CommandExists([string]$Command) {
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Test-ClaudeInstalled {
    return (Test-CommandExists 'claude') -or (Test-Path (Join-Path $UserHome '.claude'))
}

function Test-CopilotInstalled {
    $vscodeExtensions = Join-Path (Join-Path $UserHome '.vscode') 'extensions'
    return (Test-CommandExists 'copilot') `
        -or (Test-Path (Join-Path $UserHome '.copilot')) `
        -or (Test-Path (Join-Path $vscodeExtensions 'github.copilot*'))
}

function Get-DevinConfigDir {
    if ($OnWindows) { return Join-Path $env:APPDATA 'devin' }
    return Join-Path (Join-Path $UserHome '.config') 'devin'
}

function Test-DevinInstalled {
    return (Test-CommandExists 'devin') -or (Test-Path (Get-DevinConfigDir))
}

function New-Target([string]$Agent, [string]$Dir) {
    return [pscustomobject]@{ Agent = $Agent; Dir = $Dir }
}

function Get-InstalledTargets {
    $agents = @(
        @{ Agent = 'claude';  Installed = (Test-ClaudeInstalled);  Dir = (Join-Path (Join-Path $UserHome '.claude') 'skills') },
        @{ Agent = 'copilot'; Installed = (Test-CopilotInstalled); Dir = (Join-Path (Join-Path $UserHome '.copilot') 'skills') },
        @{ Agent = 'devin';   Installed = (Test-DevinInstalled);   Dir = (Join-Path (Get-DevinConfigDir) 'skills') }
    )
    foreach ($agent in $agents) {
        if ($agent.Installed) { New-Target $agent.Agent $agent.Dir }
        else { [Console]::Error.WriteLine("SKIP $($agent.Agent) (not installed)") }
    }
}

function Get-LinkTarget([string]$Path) {
    $target = @((Get-Item -LiteralPath $Path -Force).Target)[0]
    # Strips the \\?\ or \??\ prefix Windows may add to junction targets.
    return ($target -replace '^\\(\\|\?)\?\\', '').TrimEnd('\', '/')
}

function New-SkillLink([string]$Name, [string]$Agent, [string]$TargetDir) {
    $source = Join-Path $SkillsDir $Name
    $link = Join-Path $TargetDir $Name
    $existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
    if ($existing -and -not $existing.LinkType) {
        Write-Failure $Name "$link exists and is not a link; not overwriting it"
        return $false
    }
    # Deletes only the link itself, never the files it points to.
    if ($existing) { [System.IO.Directory]::Delete($link) }

    $linkType = if ($OnWindows) { 'Junction' } else { 'SymbolicLink' }
    New-Item -ItemType $linkType -Path $link -Target $source | Out-Null
    if ((Get-LinkTarget $link) -ne $source.TrimEnd('\', '/')) {
        Write-Failure $Name 'link was not created correctly'
        return $false
    }
    Write-Host "OK   ${Agent}: $Name -> $source"
    return $true
}

if ($Names -contains '--all') { $All = $true }
if ($All) { $Names = @(Get-ChildItem -LiteralPath $SkillsDir -Directory | ForEach-Object { $_.Name }) }
if (-not $Names) {
    [Console]::Error.WriteLine('Usage: register.ps1 <skill-name>... | -All')
    exit 2
}

$targets = @(Get-InstalledTargets)
if ($targets.Count -eq 0) {
    [Console]::Error.WriteLine('ERROR: no supported agent (Claude Code, GitHub Copilot, Devin for Terminal) is installed')
    exit 1
}

$failed = $false
foreach ($name in $Names) {
    if (-not (Test-Skill $name)) { $failed = $true; continue }
    foreach ($target in $targets) {
        New-Item -ItemType Directory -Force -Path $target.Dir | Out-Null
        if (-not (New-SkillLink $name $target.Agent $target.Dir)) { $failed = $true }
    }
}
if ($failed) { exit 1 }
exit 0
