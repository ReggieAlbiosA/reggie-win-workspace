# claude-code-setup.ps1
# Automated Claude Code installation with Node.js/npm dependency checking

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Status {
    param([string]$Message)
    Write-Host "  > $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  + $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "  ! $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "  ! $Message" -ForegroundColor Yellow
}

# Check if a command exists
function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# Prompt user for installation
function Prompt-Install {
    param([string]$Name)
    $response = Read-Host "  > Install $Name? (Y/N)"
    return $response -match '^[Yy]'
}

# Refresh environment PATH
function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# Check and install Node.js
function Install-NodeJs {
    Write-Host "`n[1/4] Checking Node.js..." -ForegroundColor White

    if (Test-CommandExists "node") {
        $nodeVersion = node --version
        Write-Success "Already installed: $nodeVersion"
        return $true
    }

    Write-Warning-Custom "Not installed"

    if (Prompt-Install "Node.js (required for Claude Code)") {
        Write-Status "Installing Node.js via winget..."

        try {
            winget install OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
            Refresh-Path

            if (Test-CommandExists "node") {
                $nodeVersion = node --version
                Write-Success "Installed: $nodeVersion"
                return $true
            } else {
                Write-Warning-Custom "Installed but not detected. You may need to restart your terminal."
                return $false
            }
        } catch {
            Write-Error-Custom "Installation failed: $_"
            return $false
        }
    } else {
        Write-Error-Custom "Node.js is required for Claude Code. Setup cancelled."
        return $false
    }
}

# Check npm availability
function Test-Npm {
    Write-Host "`n[2/4] Checking npm..." -ForegroundColor White

    if (Test-CommandExists "npm") {
        $npmVersion = npm --version
        Write-Success "Already installed: v$npmVersion"
        return $true
    }

    Write-Error-Custom "npm not found. npm should come with Node.js installation."
    Write-Warning-Custom "Please restart your terminal or reinstall Node.js."
    return $false
}

# Install Claude Code
function Install-ClaudeCode {
    Write-Host "`n[3/4] Checking Claude Code..." -ForegroundColor White

    if (Test-CommandExists "claude") {
        $claudeVersion = claude --version 2>$null
        Write-Success "Already installed: $claudeVersion"
        return $true
    }

    Write-Warning-Custom "Not installed"

    if (Prompt-Install "Claude Code") {
        Write-Status "Installing Claude Code via npm..."

        try {
            npm install -g @anthropic-ai/claude-code

            if ($LASTEXITCODE -eq 0) {
                Refresh-Path

                if (Test-CommandExists "claude") {
                    $claudeVersion = claude --version 2>$null
                    Write-Success "Installed successfully: $claudeVersion"
                    return $true
                } else {
                    Write-Warning-Custom "Installed but not detected. Restart your terminal to use 'claude'."
                    return $true
                }
            } else {
                Write-Error-Custom "Installation failed with exit code: $LASTEXITCODE"
                return $false
            }
        } catch {
            Write-Error-Custom "Installation failed: $_"
            return $false
        }
    } else {
        Write-Host "  > Skipped" -ForegroundColor Gray
        return $false
    }
}

# Check MCP server status (returns: "connected", "failed", or "notfound")
function Get-MCPServerStatus {
    param([string]$ServerName)
    $mcpList = claude mcp list 2>$null

    foreach ($line in $mcpList) {
        if ($line -match "^$ServerName`:") {
            if ($line -match "Connected") {
                return "connected"
            } elseif ($line -match "Failed to connect") {
                return "failed"
            }
        }
    }
    return "notfound"
}

# Prompt user to reconfigure failed MCP server
function Prompt-Reconfigure {
    param([string]$ServerName)
    $response = Read-Host "  > $ServerName failed to connect. Reconfigure? (Y/N)"
    return $response -match '^[Yy]'
}

# Remove MCP server before reconfiguring
function Remove-MCPServer {
    param([string]$ServerName)
    claude mcp remove $ServerName --scope user 2>$null
}

# Configure MCP Servers
function Add-MCPServers {
    Write-Host "`n[4/4] Configuring MCP Servers..." -ForegroundColor White

    if (-not (Test-CommandExists "claude")) {
        Write-Error-Custom "Claude Code not found. Cannot configure MCP servers."
        return $false
    }

    $success = $true

    # Add better-auth MCP server
    Write-Status "Checking better-auth MCP server..."
    $betterAuthStatus = Get-MCPServerStatus "better-auth"

    if ($betterAuthStatus -eq "connected") {
        Write-Success "better-auth connected"
    } elseif ($betterAuthStatus -eq "failed") {
        if (Prompt-Reconfigure "better-auth") {
            Remove-MCPServer "better-auth"
            Write-Status "Reconfiguring better-auth..."
            claude mcp add better-auth --scope user --transport http https://mcp.chonkie.ai/better-auth/better-auth-builder/mcp
            if ($LASTEXITCODE -eq 0) { Write-Success "better-auth reconfigured" } else { Write-Error-Custom "Failed to reconfigure better-auth"; $success = $false }
        } else {
            Write-Warning-Custom "better-auth skipped (not connected)"
        }
    } else {
        try {
            claude mcp add better-auth --scope user --transport http https://mcp.chonkie.ai/better-auth/better-auth-builder/mcp
            if ($LASTEXITCODE -eq 0) { Write-Success "better-auth added" } else { Write-Error-Custom "Failed to add better-auth"; $success = $false }
        } catch {
            Write-Error-Custom "Failed to add better-auth: $_"
            $success = $false
        }
    }

    # Add Sequential Thinking MCP server
    Write-Status "Checking sequential-thinking MCP server..."
    $seqThinkStatus = Get-MCPServerStatus "sequential-thinking"

    if ($seqThinkStatus -eq "connected") {
        Write-Success "sequential-thinking connected"
    } elseif ($seqThinkStatus -eq "failed") {
        if (Prompt-Reconfigure "sequential-thinking") {
            Remove-MCPServer "sequential-thinking"
            Write-Status "Reconfiguring sequential-thinking..."
            claude mcp add sequential-thinking --scope user cmd -- /c npx @modelcontextprotocol/server-sequential-thinking
            if ($LASTEXITCODE -eq 0) { Write-Success "sequential-thinking reconfigured" } else { Write-Error-Custom "Failed to reconfigure sequential-thinking"; $success = $false }
        } else {
            Write-Warning-Custom "sequential-thinking skipped (not connected)"
        }
    } else {
        try {
            claude mcp add sequential-thinking --scope user cmd -- /c npx @modelcontextprotocol/server-sequential-thinking
            if ($LASTEXITCODE -eq 0) { Write-Success "sequential-thinking added" } else { Write-Error-Custom "Failed to add sequential-thinking"; $success = $false }
        } catch {
            Write-Error-Custom "Failed to add sequential-thinking: $_"
            $success = $false
        }
    }

    # Add GitHub MCP server
    Write-Status "Checking github MCP server..."
    $githubStatus = Get-MCPServerStatus "github"

    if ($githubStatus -eq "connected") {
        Write-Success "github connected"
    } elseif ($githubStatus -eq "failed" -or $githubStatus -eq "notfound") {
        $action = if ($githubStatus -eq "failed") { "Reconfigure" } else { "Configure" }

        if ($githubStatus -eq "failed") {
            if (-not (Prompt-Reconfigure "github")) {
                Write-Warning-Custom "github skipped (not connected)"
                return $success
            }
            Remove-MCPServer "github"
        }

        Write-Status "$action github MCP server..."
        $githubToken = Read-Host "  > Enter your GitHub Personal Access Token"

        if ([string]::IsNullOrWhiteSpace($githubToken)) {
            Write-Warning-Custom "No token provided, skipping github MCP server"
        } else {
            # Set GITHUB_TOKEN as persistent user environment variable
            Write-Status "Setting GITHUB_TOKEN environment variable..."
            setx GITHUB_TOKEN $githubToken | Out-Null

            # Also set for current session
            $env:GITHUB_TOKEN = $githubToken

            Write-Success "GITHUB_TOKEN set"

            # Add GitHub MCP server
            Write-Status "Adding github MCP server..."
            claude mcp add github --scope user -- cmd /c npx @modelcontextprotocol/server-github

            if ($LASTEXITCODE -eq 0) {
                Write-Success "github added"
                Write-Warning-Custom "Restart PowerShell for GITHUB_TOKEN to take full effect"
            } else {
                Write-Error-Custom "Failed to add github"
                $success = $false
            }
        }
    }

    return $success
}

# Main execution
function Start-ClaudeCodeSetup {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host "    Claude Code Installation Script" -ForegroundColor Magenta
    Write-Host "==========================================" -ForegroundColor Magenta
    Write-Host ""

    # Step 1: Install Node.js
    if (-not (Install-NodeJs)) {
        Write-Host "`n=== Setup Failed ===" -ForegroundColor Red
        Write-Host "Please install Node.js manually and try again." -ForegroundColor Yellow
        return
    }

    # Step 2: Verify npm
    if (-not (Test-Npm)) {
        Write-Host "`n=== Setup Failed ===" -ForegroundColor Red
        Write-Host "npm is required but not found." -ForegroundColor Yellow
        return
    }

    # Step 3: Install Claude Code
    if (-not (Install-ClaudeCode)) {
        Write-Host "`n=== Setup Failed ===" -ForegroundColor Red
        Write-Host "Please check the errors above and try again." -ForegroundColor Yellow
        return
    }

    # Step 4: Configure MCP Servers
    Add-MCPServers

    # Success summary
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "    Setup Completed Successfully!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run 'claude' to start!" -ForegroundColor Cyan
    Write-Host "MCP servers are configured in user scope (~/.claude.json)" -ForegroundColor Cyan
    Write-Host ""
}

# Run the setup
Start-ClaudeCodeSetup
