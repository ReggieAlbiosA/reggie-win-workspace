## 🚀 One-Line Installation

Open PowerShell as **Administrator** and run:
```powershell
irm https://raw.githubusercontent.com/blueivy828/reggie-win-workspace/main/setup.ps1 | iex
```

That's it! Your browser tabs will automatically open on next login.

## 📋 What This Does

- Downloads the batch script to your Desktop
- Creates a Task Scheduler folder: `REGGIE_WORKFLOW_TASKS`
- Sets up an automated task to run on login
- Opens Microsoft Edge with your configured tabs

## 🔧 Manual Installation

If you prefer manual setup:

1. **Download the batch file:**
```powershell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/blueivy828/reggie-win-workspace/main/reggie-workflow.bat" -OutFile "$env:USERPROFILE\Desktop\reggie-workflow.bat"
```

2. **Run the setup script:**
```powershell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/blueivy828/reggie-win-workspace/main/setup.ps1" -OutFile "setup.ps1"
   .\setup.ps1
   Remove-Item setup.ps1
```

## ✏️ Customization

### Change Browser Tabs

Edit `personal-brows-tabs.bat` and modify the URLs:
```batch
@echo off
start "" msedge "https://your-url-1.com" "https://your-url-2.com"
```

### Change Browser

Replace `msedge` with:
- `chrome` - Google Chrome
- `firefox` - Firefox
- `brave` - Brave Browser

### Update Existing Installation

Just run the installation command again:
```powershell
irm https://raw.githubusercontent.com/blueivy828/reggie-win-workspace/main/setup.ps1 | iex
```

## 🗑️ Uninstallation

Remove the scheduled task:
```powershell
Unregister-ScheduledTask -TaskName "PersonalBrowserTabs" -TaskPath "\REGGIE_WORKFLOW_TASKS\" -Confirm:$false
```

Delete the batch file:
```powershell
Remove-Item "$env:USERPROFILE\Desktop\personal-brows-tabs.bat"
```

## 🛠️ Troubleshooting

### Task doesn't run on login

1. Open Task Scheduler (`taskschd.msc`)
2. Navigate to `REGGIE_WORKFLOW_TASKS`
3. Right-click `PersonalBrowserTabs` → Properties
4. Ensure "Run whether user is logged on or not" is **not** checked
5. Check "Run with highest privileges" if needed

### PowerShell execution policy error

Run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Tabs open but browser not default

The script uses Microsoft Edge by default. To use your default browser:

Edit the `.bat` file and replace `msedge` with `start`:
```batch
@echo off
start "" "https://chat.openai.com"
start "" "https://claude.ai"
start "" "https://grok.x.ai"
start "" "https://www.youtube.com"
start "" "https://github.com"
start "" "https://www.google.com"
```

## 📁 File Structure
```
.
├── personal-brows-tabs.bat    # The batch script
├── setup.ps1                  # Automated installer
└── README.md                  # This file
```

## 🔐 Security Note

The setup script requires administrator privileges to create scheduled tasks. Always review scripts before running them with elevated permissions.

## 📝 Requirements

- Windows 10/11
- PowerShell 5.1 or later
- Microsoft Edge (or modify for your browser)
- Internet connection for initial setup

## 🤝 Contributing

Feel free to fork and customize for your workflow!

## 📜 License

MIT License - Use freely for personal or commercial projects

---

**Pro Tip:** Bookmark the installation command for quick setup on new machines! 🎯
