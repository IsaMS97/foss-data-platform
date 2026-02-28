#!/usr/bin/env pwsh
<#
FOSS Data Platform Deployment Script

This script automates the deployment process by:
1. Checking for uncommitted changes
2. Determining the current branch
3. SSHing to the remote server
4. Checking out the same branch and pulling changes
5. Applying Docker Compose changes

#>

# Function definitions
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
        [int]$port,
        [string]$sshKeyPath
    )
    
    try {
        $sshTarget = $user + '@' + $hostname
        $sshCommand = "ssh -i `$sshKeyPath` -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no $sshTarget 'echo SSH connection successful'"
        $connectionTest = iex "$sshCommand 2>&1"
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
        [string]$branch,
        [string]$sshKeyPath
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
        $sshTarget = $user + '@' + $hostname
        $sshCommand = "ssh -i `$sshKeyPath` -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no $sshTarget '$fullCommand'"
        $result = iex "$sshCommand"
        
        Write-ColorText "Remote deployment completed:" "Green"
        Write-ColorText "$result" "White"
        
        return $true
    } catch {
        Write-ColorText "ERROR: Remote deployment failed: $_" "Red"
        return $false
    }
}

# Load configuration from config.json
$ConfigFile = "config.json"

if (-not (Test-Path $ConfigFile)) {
    Write-ColorText "ERROR: Configuration file $ConfigFile not found" "Red"
    Write-ColorText "Please copy config.example.json to config.json and edit it with your settings" "Yellow"
    exit 1
}

try {
    $config = Get-Content $ConfigFile | ConvertFrom-Json
    
    $RemoteUser = $config.remoteUser
    $RemoteHost = $config.remoteHost
    $RemotePath = $config.remotePath
    $SSH_PORT = $config.sshPort
    $DOCKER_COMPOSE_FILE = $config.dockerComposeFile
    $SSH_KEY_PATH = $config.sshKeyPath
    
    # Convert Windows path to Unix-style for SSH if needed
    if ($SSH_KEY_PATH -match '\\') {
        # Simple conversion for common case: C:\path\to\file -> /mnt/c/path/to/file
        $SSH_KEY_PATH = $SSH_KEY_PATH -replace '\\', '/'
        if ($SSH_KEY_PATH -like 'C:*') {
            $SSH_KEY_PATH = $SSH_KEY_PATH -replace 'C:', '/c'
            $SSH_KEY_PATH = '/mnt' + $SSH_KEY_PATH
        } elseif ($SSH_KEY_PATH -like 'D:*') {
            $SSH_KEY_PATH = $SSH_KEY_PATH -replace 'D:', '/d'
            $SSH_KEY_PATH = '/mnt' + $SSH_KEY_PATH
        }
        # Add more drive letters as needed
    }
    
    Write-ColorText "Loaded configuration from $ConfigFile" "Blue"
} catch {
    Write-ColorText "ERROR: Failed to load configuration file: $_" "Red"
    exit 1
}

# Validate configuration
if (-not $RemoteUser -or -not $RemoteHost -or -not $RemotePath) {
    Write-ColorText "ERROR: Missing required configuration values" "Red"
    Write-ColorText "Please check your $ConfigFile file" "Yellow"
    exit 1
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
if (-not (Test-SSHConnection -user $RemoteUser -hostname $RemoteHost -port $SSH_PORT -sshKeyPath $SSH_KEY_PATH)) {
    exit 1
}

# Deploy to remote
Write-ColorText "Starting deployment to $RemoteUser@$RemoteHost..." "Blue"
if (Deploy-Remote -user $RemoteUser -hostname $RemoteHost -path $RemotePath -branch $currentBranch -sshKeyPath $SSH_KEY_PATH) {
    Write-ColorText "Deployment completed successfully!" "Green"
} else {
    Write-ColorText "Deployment failed!" "Red"
    exit 1
}

Write-ColorText "=== Deployment Complete ===" "Blue"