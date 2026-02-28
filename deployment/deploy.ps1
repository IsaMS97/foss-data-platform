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
function Write-Log {
    param (
        [string]$Text
    )
    
    Write-Host $Text
}

function Test-GitStatus {
    try {
        $status = git status --porcelain
        if ($status) {
            Write-Log "ERROR: You have uncommitted changes:"
            git status
            exit 1
        }
        return $true
    } catch {
        Write-Log "ERROR: Failed to check git status: $_"
        exit 1
    }
}

function Get-CurrentBranch {
    try {
        $branch = git rev-parse --abbrev-ref HEAD
        Write-Log "Current branch: $branch"
        return $branch
    } catch {
        Write-Log "ERROR: Failed to get current branch: $_"
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
            Write-Log "SSH connection test successful"
            return $true
        } else {
            Write-Log "ERROR: SSH connection failed. Please make sure you're connected to VPN and SSH is accessible."
            Write-Log "Connection test output: $connectionTest"
            return $false
        }
    } catch {
        Write-Log "ERROR: SSH connection test failed: $_"
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
        Write-Log "Executing remote deployment..."
        $sshTarget = $user + '@' + $hostname
        $sshCommand = "ssh -i `$sshKeyPath` -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no $sshTarget '$fullCommand'"
        $result = iex "$sshCommand"
        
        Write-Log "Remote deployment completed:"
        Write-Log "$result"
        
        # Check if Docker deployment was successful
        if ($result -match "DOCKER_DEPLOYMENT_STATUS:0") {
            Write-Log "Docker deployment verified successful"
            return $true
        } else {
            Write-Log "ERROR: Docker deployment failed - non-zero exit code"
            return $false
        }
    } catch {
        Write-Log "ERROR: Remote deployment failed: $_"
        return $false
    }
}

# Load configuration from config.json
$ConfigFile = "config.json"

if (-not (Test-Path $ConfigFile)) {
    Write-Log "ERROR: Configuration file $ConfigFile not found"
    Write-Log "Please copy config.example.json to config.json and edit it with your settings"
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
    
    # Convert Windows path to forward slashes for SSH compatibility
    # SSH on Windows can handle paths like C:/Users/name/.ssh/id_rsa
    if ($SSH_KEY_PATH -match '\\') {
        $SSH_KEY_PATH = $SSH_KEY_PATH -replace '\\', '/'
    }
    
    Write-Log "Loaded configuration from $ConfigFile"
} catch {
    Write-Log "ERROR: Failed to load configuration file: $_"
    exit 1
}

# Validate configuration
if (-not $RemoteUser -or -not $RemoteHost -or -not $RemotePath) {
    Write-Log "ERROR: Missing required configuration values"
    Write-Log "Please check your $ConfigFile file"
    exit 1
}

# Main execution
Write-Log "=== FOSS Data Platform Deployment ==="

# Check for uncommitted changes
Write-Log "Checking git status..."
if (Test-GitStatus) {
    Write-Log "Git working tree is clean"
}

# Get current branch
$currentBranch = Get-CurrentBranch

# Test SSH connection
Write-Log "Testing SSH connection to $RemoteUser@$RemoteHost..."
if (-not (Test-SSHConnection -user $RemoteUser -hostname $RemoteHost -port $SSH_PORT -sshKeyPath $SSH_KEY_PATH)) {
    exit 1
}

# Deploy to remote
Write-Log "Starting deployment to $RemoteUser@$RemoteHost..."
if (Deploy-Remote -user $RemoteUser -hostname $RemoteHost -path $RemotePath -branch $currentBranch -sshKeyPath $SSH_KEY_PATH) {
    Write-Log "Deployment completed successfully!"
} else {
    Write-Log "Deployment failed!"
    exit 1
}

Write-Log "=== Deployment Complete ==="