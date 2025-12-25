# setup.ps1
# Run with: irm https://raw.githubusercontent.com/yourusername/yourrepo/main/setup.ps1 | iex

$ErrorActionPreference = "Stop"

# Configuration
$taskName = "PersonalBrowserTabs"
$taskPath = "\REGGIE_WORKFLOW_TASKS\"
$batFileName = "reggie-workflow.bat"
$batDestination = "$env:USERPROFILE\Desktop\$batFileName"
$repoUrl = "https://raw.githubusercontent.com/blueivy828/reggie-win-workspace/main/$batFileName"

Write-Host "Setting up Personal Browser Tabs automation..." -ForegroundColor Cyan

# Download the .bat file
Write-Host "Downloading $batFileName..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $repoUrl -OutFile $batDestination
Write-Host "✓ Downloaded to $batDestination" -ForegroundColor Green

# Create task folder if it doesn't exist
$scheduleService = New-Object -ComObject Schedule.Service
$scheduleService.Connect()
$rootFolder = $scheduleService.GetFolder("\")

try {
    $null = $scheduleService.GetFolder($taskPath)
    Write-Host "✓ Task folder already exists" -ForegroundColor Green
} catch {
    Write-Host "Creating task folder..." -ForegroundColor Yellow
    $null = $rootFolder.CreateFolder($taskPath)
    Write-Host "✓ Task folder created" -ForegroundColor Green
}

# Create scheduled task
Write-Host "Creating scheduled task..." -ForegroundColor Yellow

$action = New-ScheduledTaskAction -Execute $batDestination
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null

Write-Host "✓ Scheduled task created at $taskPath$taskName" -ForegroundColor Green
Write-Host "`nSetup complete! Browser tabs will open on next login." -ForegroundColor Cyan
```

## GitHub Repo Structure
```
your-repo/
├── personal-brows-tabs.bat
├── setup.ps1
└── README.md
