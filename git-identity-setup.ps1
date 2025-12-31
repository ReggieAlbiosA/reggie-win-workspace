# git-identity-setup.ps1
# Interactive Git Identity Manager - prompts for author on each commit
# Windows PowerShell version

$ErrorActionPreference = "Stop"

# File paths
$IdentitiesFile = "$env:USERPROFILE\.git-identities"
$HooksDir = "$env:USERPROFILE\.git-hooks"
$HookFile = "$HooksDir\pre-commit"

# Helper function to check if a command exists
function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Helper function to validate email format
function Test-EmailFormat {
    param([string]$Email)
    return $Email -match '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
}

# Check Git installation
function Test-GitInstalled {
    Write-Host "`n[1/5] Checking Git..." -ForegroundColor White

    if (Test-CommandExists "git") {
        $gitVersion = git --version
        Write-Host "  + Git installed: $gitVersion" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  ! Git is not installed. Please install Git first." -ForegroundColor Red
        return $false
    }
}

# Check for existing identities file
function Test-ExistingIdentities {
    Write-Host "`n[2/5] Checking existing identities..." -ForegroundColor White

    if (Test-Path $IdentitiesFile) {
        $lines = Get-Content $IdentitiesFile
        $count = $lines.Count
        Write-Host "  ! Found existing identities file with $count identity/identities" -ForegroundColor Yellow
        Write-Host "    Location: $IdentitiesFile" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Current identities:" -ForegroundColor Cyan

        foreach ($line in $lines) {
            $parts = $line -split ':'
            if ($parts.Count -ge 4) {
                $num = $parts[0]
                $email = $parts[2]
                $label = $parts[3]
                Write-Host "    $num) $label ($email)"
            }
        }

        Write-Host ""
        $response = Read-Host "  > Keep existing identities? (y = keep, n = reconfigure)"

        if ($response -match '^[Yy]') {
            Write-Host "  + Keeping existing identities" -ForegroundColor Green
            return $false  # Skip collection
        } else {
            Write-Host "  > Will reconfigure identities" -ForegroundColor Yellow
            Remove-Item $IdentitiesFile -Force
            return $true  # Proceed with collection
        }
    } else {
        Write-Host "  i No existing identities found" -ForegroundColor Gray
        return $true  # Proceed with collection
    }
}

# Collect identities from user
function Get-Identities {
    Write-Host "`n[3/5] Collecting Git identities..." -ForegroundColor White
    Write-Host "  i You can add multiple identities (Work, Personal, Client, etc.)" -ForegroundColor Gray
    Write-Host ""

    $identityCount = 0

    while ($true) {
        Write-Host "  --- Identity #$($identityCount + 1) ---" -ForegroundColor Magenta

        # Get label
        $label = ""
        while ([string]::IsNullOrWhiteSpace($label)) {
            $label = Read-Host "  > Enter identity name (e.g., 'Work', 'Personal', 'Client')"
            if ([string]::IsNullOrWhiteSpace($label)) {
                Write-Host "    ! Identity name cannot be empty" -ForegroundColor Red
            }
        }

        # Get full name
        $name = ""
        while ([string]::IsNullOrWhiteSpace($name)) {
            $name = Read-Host "  > Enter full name for commits"
            if ([string]::IsNullOrWhiteSpace($name)) {
                Write-Host "    ! Name cannot be empty" -ForegroundColor Red
            }
        }

        # Get email
        $email = ""
        while ($true) {
            $email = Read-Host "  > Enter email for commits"
            if ([string]::IsNullOrWhiteSpace($email)) {
                Write-Host "    ! Email cannot be empty" -ForegroundColor Red
            } elseif (-not (Test-EmailFormat $email)) {
                Write-Host "    ! Invalid email format. Please include @" -ForegroundColor Red
            } else {
                break
            }
        }

        # Save identity
        $identityCount++
        $identityLine = "${identityCount}:${name}:${email}:${label}"
        Add-Content -Path $IdentitiesFile -Value $identityLine
        Write-Host "  + Added: $label ($email)" -ForegroundColor Green
        Write-Host ""

        # Ask for more
        $response = Read-Host "  > Add another identity? (a = add more, x = done)"

        if ($response -match '^[Xx]') {
            break
        }
        Write-Host ""
    }

    if ($identityCount -eq 0) {
        Write-Host "  ! At least one identity is required" -ForegroundColor Red
        return $false
    }

    Write-Host "  + Saved $identityCount identity/identities to $IdentitiesFile" -ForegroundColor Green
    return $true
}

# Create the pre-commit hook (bash script for Git Bash)
function New-PreCommitHook {
    Write-Host "`n[4/5] Creating pre-commit hook..." -ForegroundColor White

    # Create hooks directory
    if (-not (Test-Path $HooksDir)) {
        New-Item -ItemType Directory -Path $HooksDir -Force | Out-Null
    }
    Write-Host "  + Created hooks directory: $HooksDir" -ForegroundColor Green

    # Generate the hook script (bash - Git for Windows uses Git Bash)
    $hookContent = @'
#!/bin/bash
# Global pre-commit hook - Git Identity Manager
# Dynamically generated by git-identity-setup.ps1

IDENTITIES_FILE="$HOME/.git-identities"

# Check if identities file exists
if [ ! -f "$IDENTITIES_FILE" ]; then
    echo "Error: Git identities file not found at $IDENTITIES_FILE"
    echo "Run git-identity-setup.ps1 to configure identities."
    exit 1
fi

# Function to display menu and get selection
show_menu() {
    # Get current identity
    CURRENT_EMAIL=$(git config user.email 2>/dev/null || echo "not set")

    # Find current label if it matches
    CURRENT_LABEL=""
    while IFS=: read -r num name email label; do
        if [ "$email" = "$CURRENT_EMAIL" ]; then
            CURRENT_LABEL=" ($label)"
            break
        fi
    done < "$IDENTITIES_FILE"

    echo ""
    echo "Current identity: $CURRENT_EMAIL$CURRENT_LABEL"
    echo ""
    echo "Choose commit identity:"

    # Read and display identities
    while IFS=: read -r num name email label; do
        echo "$num) $label ($email)"
    done < "$IDENTITIES_FILE"

    echo "a) Add new identity"
    echo "Enter) Keep current"
    echo ""
}

# Function to add new identity
add_identity() {
    echo ""
    echo "--- Add New Identity ---"

    # Get next number
    local next_num=$(($(wc -l < "$IDENTITIES_FILE") + 1))

    # Get label
    local label=""
    while [ -z "$label" ]; do
        read -p "Enter identity name (e.g., 'Work', 'Personal'): " label < /dev/tty
        if [ -z "$label" ]; then
            echo "Identity name cannot be empty"
        fi
    done

    # Get full name
    local name=""
    while [ -z "$name" ]; do
        read -p "Enter full name for commits: " name < /dev/tty
        if [ -z "$name" ]; then
            echo "Name cannot be empty"
        fi
    done

    # Get email
    local email=""
    while true; do
        read -p "Enter email for commits: " email < /dev/tty
        if [ -z "$email" ]; then
            echo "Email cannot be empty"
        elif [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo "Invalid email format"
        else
            break
        fi
    done

    # Save identity
    echo "$next_num:$name:$email:$label" >> "$IDENTITIES_FILE"
    echo ""
    echo "Added: $label ($email)"
    echo ""
}

# Main loop
while true; do
    show_menu

    # Read from terminal directly (git hooks don't have stdin)
    read -p "Select: " choice < /dev/tty

    # Handle 'a' - add new identity
    if [[ "$choice" =~ ^[Aa]$ ]]; then
        add_identity
        continue
    fi

    # Handle empty - keep current
    if [ -z "$choice" ]; then
        echo "Keeping current identity"
        exit 0
    fi

    # Handle number selection
    SELECTED=$(grep "^$choice:" "$IDENTITIES_FILE")

    if [ -z "$SELECTED" ]; then
        echo "Invalid choice. Try again."
        continue
    fi

    # Parse selected identity
    NAME=$(echo "$SELECTED" | cut -d: -f2)
    EMAIL=$(echo "$SELECTED" | cut -d: -f3)
    LABEL=$(echo "$SELECTED" | cut -d: -f4)

    # Apply identity to this repo
    git config user.name "$NAME"
    git config user.email "$EMAIL"
    echo "Switched to $LABEL ($EMAIL)"
    exit 0
done
'@

    # Write hook file (use LF line endings for bash)
    $hookContent | Set-Content -Path $HookFile -Encoding UTF8 -NoNewline
    # Convert to Unix line endings
    $content = Get-Content $HookFile -Raw
    $content = $content -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($HookFile, $content)

    Write-Host "  + Created pre-commit hook: $HookFile" -ForegroundColor Green
    return $true
}

# Configure Git to use global hooks
function Set-GitHooksPath {
    Write-Host "`n[5/5] Configuring Git global hooks..." -ForegroundColor White

    # Convert Windows path to Unix-style for Git
    $unixHooksDir = $HooksDir -replace '\\', '/'
    git config --global core.hooksPath $unixHooksDir
    Write-Host "  + Set global hooks path: $HooksDir" -ForegroundColor Green

    # Set first identity as default (required for git to allow commits)
    if (Test-Path $IdentitiesFile) {
        $firstLine = Get-Content $IdentitiesFile -First 1
        if ($firstLine) {
            $parts = $firstLine -split ':'
            if ($parts.Count -ge 4) {
                $defaultName = $parts[1]
                $defaultEmail = $parts[2]
                $defaultLabel = $parts[3]

                git config --global user.name $defaultName
                git config --global user.email $defaultEmail
                Write-Host "  + Set default identity: $defaultLabel ($defaultEmail)" -ForegroundColor Green
            }
        }
    }

    return $true
}

# Show completion message
function Show-Success {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "    Git Identity Manager Installed!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "How it works:" -ForegroundColor Cyan
    Write-Host "  - On every commit, you'll be prompted to choose an identity"
    Write-Host "  - Press Enter to keep current identity, or select a number"
    Write-Host ""
    Write-Host "Configuration files:" -ForegroundColor Cyan
    Write-Host "  Identities: $IdentitiesFile" -ForegroundColor Gray
    Write-Host "  Hook:       $HookFile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To manage identities:" -ForegroundColor Cyan
    Write-Host "  Edit:   notepad $IdentitiesFile" -ForegroundColor Gray
    Write-Host "  Format: number:Full Name:email@example.com:Label" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Note: The hook runs on ALL git repositories for this user." -ForegroundColor Yellow
    Write-Host ""
}

# Main execution
function Start-GitIdentitySetup {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host "    Git Identity Manager Setup" -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host ""

    # Step 1: Check Git
    if (-not (Test-GitInstalled)) {
        Write-Host "`n=== Setup Failed ===" -ForegroundColor Red
        return
    }

    # Step 2: Check existing identities
    $shouldCollect = Test-ExistingIdentities

    # Step 3: Collect identities (if needed)
    if ($shouldCollect) {
        if (-not (Get-Identities)) {
            Write-Host "`n=== Setup Failed ===" -ForegroundColor Red
            Write-Host "At least one identity is required." -ForegroundColor Yellow
            return
        }
    }

    # Step 4: Create hook
    if (-not (New-PreCommitHook)) {
        Write-Host "`n=== Setup Failed ===" -ForegroundColor Red
        return
    }

    # Step 5: Configure Git
    if (-not (Set-GitHooksPath)) {
        Write-Host "`n=== Setup Failed ===" -ForegroundColor Red
        return
    }

    # Show success
    Show-Success
}

# Run the setup
Start-GitIdentitySetup
