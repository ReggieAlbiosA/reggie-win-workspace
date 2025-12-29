# setup.ps1
# Run with: irm https://raw.githubusercontent.com/blueivy828/reggie-win-workspace/refs/heads/main/setup.ps1 | iex

$ErrorActionPreference = "Stop"

# Helper function to check if a command exists
function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Helper function to prompt user
function Prompt-Install {
    param([string]$Name)
    $response = Read-Host "  > Install $Name? (y/n)"
    return $response -match '^[Yy]'
}

Write-Host "`n=== Checking Dependencies ===" -ForegroundColor Cyan

# --- Check Node.js ---
Write-Host "`n[1/7] Node.js" -ForegroundColor White
if (Test-CommandExists "node") {
    $nodeVersion = node --version
    Write-Host "  + Already installed: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "  - Not installed" -ForegroundColor Yellow
    if (Prompt-Install "Node.js") {
        Write-Host "  > Installing Node.js..." -ForegroundColor Cyan
        winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        if (Test-CommandExists "node") {
            Write-Host "  + Installed: $(node --version)" -ForegroundColor Green
        } else {
            Write-Host "  ! Installed. Restart terminal to use node." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  > Skipped" -ForegroundColor Gray
    }
}

# --- Check Git ---
Write-Host "`n[2/7] Git" -ForegroundColor White
if (Test-CommandExists "git") {
    $gitVersion = git --version
    Write-Host "  + Already installed: $gitVersion" -ForegroundColor Green
} else {
    Write-Host "  - Not installed" -ForegroundColor Yellow
    if (Prompt-Install "Git") {
        Write-Host "  > Installing Git..." -ForegroundColor Cyan
        winget install Git.Git --accept-source-agreements --accept-package-agreements
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        if (Test-CommandExists "git") {
            Write-Host "  + Installed: $(git --version)" -ForegroundColor Green
        } else {
            Write-Host "  ! Installed. Restart terminal to use git." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  > Skipped" -ForegroundColor Gray
    }
}

# --- Check pnpm ---
Write-Host "`n[3/7] pnpm" -ForegroundColor White
if (Test-CommandExists "pnpm") {
    $pnpmVersion = pnpm --version
    Write-Host "  + Already installed: v$pnpmVersion" -ForegroundColor Green
} else {
    Write-Host "  - Not installed" -ForegroundColor Yellow
    if (Prompt-Install "pnpm") {
        Write-Host "  > Installing pnpm..." -ForegroundColor Cyan
        Invoke-WebRequest https://get.pnpm.io/install.ps1 -UseBasicParsing | Invoke-Expression
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        $env:PNPM_HOME = [System.Environment]::GetEnvironmentVariable("PNPM_HOME","User")
        if ($env:PNPM_HOME) { $env:Path = "$env:PNPM_HOME;$env:Path" }
        if (Test-CommandExists "pnpm") {
            Write-Host "  + Installed: v$(pnpm --version)" -ForegroundColor Green
        } else {
            Write-Host "  ! Installed. Restart terminal to use pnpm." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  > Skipped" -ForegroundColor Gray
    }
}

# --- Check VS Code ---
Write-Host "`n[4/7] VS Code" -ForegroundColor White
if (Test-CommandExists "code") {
    $codeVersion = code --version | Select-Object -First 1
    Write-Host "  + Already installed: v$codeVersion" -ForegroundColor Green
} else {
    Write-Host "  - Not installed" -ForegroundColor Yellow
    if (Prompt-Install "VS Code") {
        Write-Host "  > Installing VS Code..." -ForegroundColor Cyan
        winget install --id Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        if (Test-CommandExists "code") {
            $codeVersion = code --version | Select-Object -First 1
            Write-Host "  + Installed: v$codeVersion" -ForegroundColor Green
        } else {
            Write-Host "  ! Installed. Restart terminal to use code." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  > Skipped" -ForegroundColor Gray
    }
}

# --- Check Cursor ---
Write-Host "`n[5/7] Cursor" -ForegroundColor White
if (Test-CommandExists "cursor") {
    Write-Host "  + Already installed" -ForegroundColor Green
} else {
    Write-Host "  - Not installed" -ForegroundColor Yellow
    if (Prompt-Install "Cursor") {
        Write-Host "  > Installing Cursor..." -ForegroundColor Cyan
        winget install -e --id Anysphere.Cursor --accept-source-agreements --accept-package-agreements
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        if (Test-CommandExists "cursor") {
            Write-Host "  + Installed" -ForegroundColor Green
        } else {
            Write-Host "  ! Installed. Restart terminal to use cursor." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  > Skipped" -ForegroundColor Gray
    }
}

# --- Check Google Antigravity ---
Write-Host "`n[6/7] Google Antigravity" -ForegroundColor White
if (Test-CommandExists "antigravity") {
    Write-Host "  + Already installed" -ForegroundColor Green
} else {
    Write-Host "  - Not installed" -ForegroundColor Yellow
    if (Prompt-Install "Google Antigravity") {
        Write-Host "  > Installing Google Antigravity..." -ForegroundColor Cyan
        winget install -e --id Google.Antigravity --accept-source-agreements --accept-package-agreements
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        if (Test-CommandExists "antigravity") {
            Write-Host "  + Installed" -ForegroundColor Green
        } else {
            Write-Host "  ! Installed. Restart terminal to use antigravity." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  > Skipped" -ForegroundColor Gray
    }
}

# --- Claude Code Setup (Modular) ---
Write-Host "`n[7/7] Claude Code" -ForegroundColor White
if (Test-CommandExists "claude") {
    $claudeVersion = claude --version 2>$null
    Write-Host "  + Already installed: $claudeVersion" -ForegroundColor Green
    Write-Host "  i Run 'claude-code-setup.ps1' separately to configure MCP servers" -ForegroundColor Gray
} else {
    Write-Host "  - Not installed" -ForegroundColor Yellow
    if (Prompt-Install "Claude Code (includes MCP servers setup)") {
        Write-Host "  > Running Claude Code setup..." -ForegroundColor Cyan

        # Determine script location (local or remote)
        $claudeSetupScript = "$PSScriptRoot\claude-code-setup.ps1"

        if (Test-Path $claudeSetupScript) {
            # Local: dot-source the script
            . $claudeSetupScript
        } else {
            # Remote: download and execute from GitHub
            $claudeSetupUrl = "https://raw.githubusercontent.com/blueivy828/reggie-win-workspace/refs/heads/main/claude-code-setup.ps1"
            Write-Host "  > Downloading claude-code-setup.ps1..." -ForegroundColor Cyan
            Invoke-WebRequest -Uri $claudeSetupUrl -UseBasicParsing | Invoke-Expression
        }
    } else {
        Write-Host "  > Skipped" -ForegroundColor Gray
    }
}

Write-Host "`n=== Setting up Workspace ===" -ForegroundColor Cyan

# Configuration
$batFileName = "reggie-workspace.bat"
$batDestination = "$env:USERPROFILE\Desktop\$batFileName"
$repoUrl = "https://raw.githubusercontent.com/blueivy828/reggie-win-workspace/refs/heads/main/$batFileName"
$taskName = "ReggieWorkspace"

Write-Host "`nSetting up Reggie Workspace automation..." -ForegroundColor Cyan

# Download the .bat file
Write-Host "Downloading $batFileName..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $repoUrl -OutFile $batDestination
Write-Host "  + Downloaded to $batDestination" -ForegroundColor Green

# Remove old startup shortcut if it exists (cleanup from previous setup method)
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = "$startupFolder\ReggieWorkspace.lnk"
if (Test-Path $shortcutPath) {
    Remove-Item $shortcutPath -Force
    Write-Host "  + Removed old startup shortcut" -ForegroundColor Yellow
}

# Create scheduled task to run at logon
Write-Host "Setting up Task Scheduler task..." -ForegroundColor Yellow

# Remove existing task if it exists
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "  + Removed existing scheduled task" -ForegroundColor Yellow
}

# Create the scheduled task action
$action = New-ScheduledTaskAction -Execute $batDestination -WorkingDirectory (Split-Path $batDestination -Parent)

# Create the trigger - run at user logon
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

# Create task settings
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

# Register the scheduled task (no admin required for user-level task)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Reggie Workspace - Opens browser tabs and apps on login" | Out-Null

Write-Host "  + Scheduled task created" -ForegroundColor Green

# Setup PowerShell Profile with aliases
Write-Host "`nSetting up PowerShell profile aliases..." -ForegroundColor Yellow

$startMarker = "# >>> REGGIE-WORKSPACE-ALIASES >>>"
$endMarker = "# <<< REGGIE-WORKSPACE-ALIASES <<<"

$profileContent = @"
$startMarker
# Git Aliases
function gs { git status }
function ga { git add `$args }
function gc { git commit -m `$args }
function gp { git push }
function gl { git log --oneline --decorate --graph }
function gd { git diff }
function gco { git checkout `$args }
function gb { git branch `$args }
function gpull { git pull }
function gsw { git switch `$args }

# ubuntu default cli
Set-Alias pwd Get-Location
Set-Alias find fd
function ~ { Set-Location `$HOME }

Remove-Alias ls -Force -ErrorAction SilentlyContinue

function ls {
    param(
        [Switch]`$l,  # Long format
        [Switch]`$a   # Show hidden
    )
    `$params = @()
    if (`$l) { `$params += '-Force' }  # Detailed view (approx -l)
    if (`$a -or `$l) { `$params += '-Hidden' }  # Show hidden (approx -a)
    Get-ChildItem @params @args
}

function touch {
    param([Parameter(Mandatory=`$true)][string]`$Path)
    if (Test-Path `$Path) {
        (Get-Item `$Path).LastWriteTime = Get-Date
    } else {
        New-Item -ItemType File -Path `$Path | Out-Null
    }
}

Set-Alias cat Get-Content

function mv {
    param([Parameter(Mandatory=`$true)][string[]]`$Path, [Parameter(Mandatory=`$true)][string]`$Destination)
    Move-Item -Path `$Path -Destination `$Destination -Force
}
Set-Alias mv Move-Item

function cp {
    param([Parameter(Mandatory=`$true)][string[]]`$Path, [Parameter(Mandatory=`$true)][string]`$Destination)
    Copy-Item -Path `$Path -Destination `$Destination -Force
}
$endMarker
"@

# Create profile directory if it doesn't exist
$profileDir = Split-Path $PROFILE -Parent
if (!(Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

# Read existing profile or create empty
if (Test-Path $PROFILE) {
    $existingContent = Get-Content $PROFILE -Raw
    if ($null -eq $existingContent) { $existingContent = "" }
} else {
    $existingContent = ""
}

# Check if markers exist and replace, otherwise append
if ($existingContent -match "(?s)$([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker))") {
    # Replace existing section
    $newContent = $existingContent -replace "(?s)$([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker))", $profileContent
    Write-Host "V PowerShell profile updated at: $PROFILE" -ForegroundColor Green
} else {
    # Append to profile
    $newContent = $existingContent.TrimEnd() + "`n`n" + $profileContent
    Write-Host "V PowerShell profile aliases added to: $PROFILE" -ForegroundColor Green
}

Set-Content -Path $PROFILE -Value $newContent -Force

Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host "  + Scheduled task created (runs at logon via Task Scheduler)" -ForegroundColor Green
Write-Host "  + PowerShell aliases configured (restart terminal to use)" -ForegroundColor Green
Write-Host "`nTo test now, run: $batDestination" -ForegroundColor Gray
Write-Host "To manage the task, open Task Scheduler and look for '$taskName'" -ForegroundColor Gray
