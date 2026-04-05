$ErrorActionPreference = 'Stop'

# Run from the script directory so relative paths are stable.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$pythonCandidates = @(
    '.venv/Scripts/python.exe',
    '.venv/bin/python',
    'python',
    'python3'
)

$pythonCmd = $null
foreach ($candidate in $pythonCandidates) {
    if ($candidate -like '*/*' -or $candidate -like '*\\*') {
        if (Test-Path $candidate) {
            $pythonCmd = $candidate
            break
        }
    } else {
        $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($null -ne $cmd) {
            $pythonCmd = $cmd.Source
            break
        }
    }
}

if ($null -eq $pythonCmd) {
    Write-Error 'Python not found. Activate/install Python first.'
}

& $pythonCmd 'top_ils.py' @args
