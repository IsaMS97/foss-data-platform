#!/usr/bin/env pwsh
<#
FOSS Data Platform Deployment Script

This script automates the deployment process by:
1. Checking for uncommitted changes
2. Determining the current branch
3. SSHing to the remote server
4. Checking out the same branch and pulling changes
5. Applying Docker Compose changes

Usage: .\deploy.ps1 -RemoteUser username -RemoteHost hostname -RemotePath "/path/to/repo"
#>

param (
    [Parameter(Mandatory=$false)]
    [string]$RemoteUser,
    
    [Parameter(Mandatory=$false)]
    [string]$RemoteHost,
    
    [Parameter(Mandatory=$false)]
    [string]$RemotePath,
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "deploy.config.json"
)

# Configuration
$SSH_PORT = 22
$DOCKER_COMPOSE_FILE = "docker-compose.yml"

# Load configuration from file if parameters not provided
if (-not $RemoteUser -or -not $RemoteHost -or -not $RemotePath) {
    if (Test-Path $ConfigFile) {
        try {
            $config = Get-Content $ConfigFile | ConvertFrom-Json
            
            if (-not $RemoteUser) { $RemoteUser = $config.remoteUser }
            if (-not $RemoteHost) { $RemoteHost = $config.remoteHost }
            if (-not $RemotePath) { $RemotePath = $config.remotePath }
            if ($config.sshPort) { $SSH_PORT = $config.sshPort }
            if ($config.dockerComposeFile) { $DOCKER_COMPOSE_FILE = $config.dockerComposeFile }
            
            Write-ColorText "Loaded configuration from $ConfigFile" "Blue"
        } catch {
            Write-ColorText "ERROR: Failed to load configuration file: $_" "Red"
            exit 1
        }
    } else {
        Write-ColorText "ERROR: Configuration file $ConfigFile not found and required parameters not provided" "Red"
        Write-ColorText "Usage: .\deploy.ps1 -RemoteUser username -RemoteHost hostname -RemotePath /path/to/repo" "Yellow"
        Write-ColorText "Or create a $ConfigFile configuration file" "Yellow"
        exit 1
    }
}

# Validate required parameters
if (-not $RemoteUser -or -not $RemoteHost -or -not $RemotePath) {
    Write-ColorText "ERROR: Missing required parameters" "Red"
    Write-ColorText "Usage: .\deploy.ps1 -RemoteUser username -RemoteHost hostname -RemotePath /path/to/repo" "Yellow"
    exit 1
}

function Write-ColorText {
    param (
        [string]$Text,
        [string]$Color = "White"
    )
    
    $colors = @{
        "Red" = "31"
        "Green" = "32"
        "Yellow" = "33"
        "Blue" = "34"
        "White" = "37"
    }
    
    if ($colors.ContainsKey($Color)) {
        Write-Host "`e[${color}m$Text`e[0m"
    } else {
        Write-Host $Text
    }
}

function Test-GitStatus {
    try {
        $status = git status --porcelain
        if ($status) {
            Write-ColorText "ERROR: You have uncommitted changes:" "Red"
            git status
            exit 1
        }
        return $true
    } catch {
        Write-ColorText "ERROR: Failed to check git status: $_" "Red"
        exit 1
    }
}

function Get-CurrentBranch {
    try {
        $branch = git rev-parse --abbrev-ref HEAD
        Write-ColorText "Current branch: $branch" "Blue"
        return $branch
    } catch {
        Write-ColorText "ERROR: Failed to get current branch: $_" "Red"
        exit 1
    }
}

function Test-SSHConnection {
    param(
        [string]$user,
        [string]$hostname,
        [int]$port
    )
    
    try {
        $connectionTest = ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no "$user@$hostname" "echo 'SSH connection successful'" 2>&1
        if ($connectionTest -match "SSH connection successful") {
            Write-ColorText "SSH connection test successful" "Green"
            return $true
        } else {
            Write-ColorText "ERROR: SSH connection failed. Please make sure you're connected to VPN and SSH is accessible." "Red"
            Write-ColorText "Connection test output: $connectionTest" "Yellow"
            return $false
        }
    } catch {
        Write-ColorText "ERROR: SSH connection test failed: $_" "Red"
        return $false
    }
}

function Deploy-Remote {
    param(
        [string]$user,
        [string]$hostname,
        [string]$path,
        [string]$branch
    )
    
    $sshCommand = @(
        "cd $path",
        "git fetch origin",
        "git checkout $branch",
        "git pull origin $branch",
        "docker compose -f $DOCKER_COMPOSE_FILE pull",
        "docker compose -f $DOCKER_COMPOSE_FILE up -d --remove-orphans"
    )
    
    $fullCommand = $sshCommand -join "; "
    
    try {
        Write-ColorText "Executing remote deployment..." "Blue"
        $result = ssh "$user@$hostname" "$fullCommand"
        
        Write-ColorText "Remote deployment completed:" "Green"
        Write-ColorText "$result" "White"
        
        return $true
    } catch {
        Write-ColorText "ERROR: Remote deployment failed: $_" "Red"
        return $false
    }
}

# Main execution
Write-ColorText "=== FOSS Data Platform Deployment ===" "Blue"

# Check for uncommitted changes
Write-ColorText "Checking git status..." "Blue"
if (Test-GitStatus) {
    Write-ColorText "Git working tree is clean" "Green"
}

# Get current branch
$currentBranch = Get-CurrentBranch

# Test SSH connection
Write-ColorText "Testing SSH connection to $RemoteUser@$RemoteHost..." "Blue"
if (-not (Test-SSHConnection -user $RemoteUser -hostname $RemoteHost -port $SSH_PORT)) {
    exit 1
}

# Deploy to remote
Write-ColorText "Starting deployment to $RemoteUser@$RemoteHost..." "Blue"
if (Deploy-Remote -user $RemoteUser -hostname $RemoteHost -path $RemotePath -branch $currentBranch) {
    Write-ColorText "Deployment completed successfully!" "Green"
} else {
    Write-ColorText "Deployment failed!" "Red"
    exit 1
}

Write-ColorText "=== Deployment Complete ===" "Blue"