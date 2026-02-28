# Deployment Script

This PowerShell script automates the deployment of your FOSS Data Platform to a remote server.

## Prerequisites

1. **PowerShell 7+** (recommended for best compatibility)
2. **Git** installed and in PATH
3. **SSH client** (OpenSSH) installed and in PATH
4. **SSH key setup** for password-less authentication to your remote server
5. **VPN connection** established before running the script

## Installation

No installation needed. Just ensure you have the prerequisites above.

## Usage

```powershell
# Using configuration file (recommended)
.\deploy.ps1

# Using command line parameters
.\deploy.ps1 -RemoteUser username -RemoteHost hostname -RemotePath "/path/to/repo"

# Using custom config file
.\deploy.ps1 -ConfigFile "custom.config.json"

# Example with parameters
.\deploy.ps1 -RemoteUser deploy -RemoteHost my-server.internal -RemotePath "/opt/foss-data-platform"
```

## Configuration File

Create a `deploy.config.json` file in the same directory as the script:

```json
{
    "remoteUser": "your_username",
    "remoteHost": "your-server.internal",
    "remotePath": "/path/to/foss-data-platform",
    "sshPort": 22,
    "dockerComposeFile": "docker-compose.yml"
}
```

## What the Script Does

1. **Checks for uncommitted changes**: Ensures your working directory is clean
2. **Determines current branch**: Gets the branch you're currently on
3. **Tests SSH connection**: Verifies you can connect to the remote server
4. **Deploys to remote server**:
   - Changes to the specified directory
   - Fetches latest changes from origin
   - Checks out the same branch you're on locally
   - Pulls the latest changes
   - Pulls updated Docker images
   - Starts containers with `docker compose up -d --remove-orphans`

## Configuration

The script uses the following defaults:
- SSH port: 22
- Docker Compose file: `docker-compose.yml`

## Troubleshooting

### SSH Connection Issues
- Make sure you're connected to your VPN
- Verify SSH is accessible on the remote server
- Ensure your SSH keys are properly set up
- Test manual SSH connection first: `ssh username@hostname`

### Git Issues
- Make sure you have committed all changes before running the script
- Ensure the remote branch exists on the server

### Docker Compose Issues
- Verify Docker and Docker Compose are installed on the remote server
- Check that the Docker Compose file exists in the specified path

## Security Notes

- The script uses SSH for secure communication
- No passwords are stored or transmitted in plain text
- Make sure your SSH keys are protected with a passphrase
- Only run this script from trusted environments