# logon-launch-workspace.ps1
# Modular script to set up workspace launcher scheduled task
# Can be run standalone or called from setup.ps1

$ErrorActionPreference = "Stop"

# Configuration
$BatFileName = "launch-workspace.bat"
$BatDestination = "$env:USERPROFILE\Desktop\$BatFileName"
$RepoUrl = "https://raw.githubusercontent.com/blueivy828/reggie-win-workspace/refs/heads/main/$BatFileName"
$TaskName = "ReggieWorkspace"
$StartupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$OldShortcutPath = "$StartupFolder\ReggieWorkspace.lnk"

# Prepare workspace launcher
function Install-WorkspaceLauncher {
    Write-Host "`n[1/3] Preparing workspace launcher..." -ForegroundColor White

    # Check for local file first
    $localBat = "$PSScriptRoot\$BatFileName"

    if (Test-Path $localBat) {
        Write-Host "  + Found local: $localBat" -ForegroundColor Green
        Copy-Item -Path $localBat -Destination $BatDestination -Force
        Write-Host "  + Copied to Desktop" -ForegroundColor Green
    } else {
        Write-Host "  i Local file not found, downloading from GitHub..." -ForegroundColor Gray
        try {
            Invoke-WebRequest -Uri $RepoUrl -OutFile $BatDestination -UseBasicParsing
            Write-Host "  + Downloaded to: $BatDestination" -ForegroundColor Green
        } catch {
            Write-Host "  ! Failed to download: $_" -ForegroundColor Red
            return $false
        }
    }

    return $true
}

# Clean up old startup methods
function Remove-OldStartupMethods {
    Write-Host "`n[2/3] Cleaning up old startup methods..." -ForegroundColor White

    # Remove old startup shortcut if exists
    if (Test-Path $OldShortcutPath) {
        Remove-Item $OldShortcutPath -Force
        Write-Host "  + Removed old startup shortcut" -ForegroundColor Yellow
    } else {
        Write-Host "  i No old startup shortcut found" -ForegroundColor Gray
    }

    # Remove existing scheduled task if exists
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "  + Removed existing scheduled task" -ForegroundColor Yellow
    }

    return $true
}

# Create scheduled task
function New-WorkspaceScheduledTask {
    Write-Host "`n[3/3] Creating scheduled task..." -ForegroundColor White

    if (-not (Test-Path $BatDestination)) {
        Write-Host "  ! Launcher not found at: $BatDestination" -ForegroundColor Red
        return $false
    }

    try {
        # Create the scheduled task action
        $action = New-ScheduledTaskAction -Execute $BatDestination -WorkingDirectory (Split-Path $BatDestination -Parent)

        # Create the trigger - run at user logon
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

        # Create task settings
        $settings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -StartWhenAvailable `
            -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

        # Register the scheduled task
        Register-ScheduledTask `
            -TaskName $TaskName `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -Description "Reggie Workspace - Opens browser tabs and apps on login" | Out-Null

        Write-Host "  + Scheduled task '$TaskName' created" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  ! Failed to create scheduled task: $_" -ForegroundColor Red
        return $false
    }
}

# Show completion message
function Show-Success {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "    Workspace Launcher Configured!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "What happens on login:" -ForegroundColor Cyan
    Write-Host "  - Opens browser tabs (ChatGPT, Claude, Grok, YouTube, GitHub, Google)"
    Write-Host "  - Opens PowerShell terminal"
    Write-Host "  - Opens Obsidian"
    Write-Host ""
    Write-Host "Configuration:" -ForegroundColor Cyan
    Write-Host "  Launcher: $BatDestination" -ForegroundColor Gray
    Write-Host "  Task:     $TaskName (in Task Scheduler)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To customize:" -ForegroundColor Cyan
    Write-Host "  Edit: notepad $BatDestination" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To test now:" -ForegroundColor Yellow
    Write-Host "  Run: $BatDestination" -ForegroundColor Gray
    Write-Host ""
}

# Main execution
function Start-WorkspaceLauncherSetup {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host "    Workspace Launcher Setup" -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor Magenta

    # Step 1: Install launcher
    if (-not (Install-WorkspaceLauncher)) {
        Write-Host "`n=== Setup Failed ===" -ForegroundColor Red
        return
    }

    # Step 2: Clean up old methods
    if (-not (Remove-OldStartupMethods)) {
        Write-Host "`n=== Setup Failed ===" -ForegroundColor Red
        return
    }

    # Step 3: Create scheduled task
    if (-not (New-WorkspaceScheduledTask)) {
        Write-Host "`n=== Setup Failed ===" -ForegroundColor Red
        return
    }

    # Show success
    Show-Success
}

# Run the setup
Start-WorkspaceLauncherSetup
