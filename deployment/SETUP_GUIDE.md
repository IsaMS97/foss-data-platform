# Deployment Setup Guide

## 📁 Folder Structure

```
deployment/
├── deploy.ps1              # Main deployment script
├── DEPLOYMENT.md           # Complete documentation
├── DEPLOYMENT_SUMMARY.md   # Implementation summary
├── SETUP_GUIDE.md          # This guide
├── config.example.json     # Example configuration (committed)
└── config.json             # Your actual config (in .gitignore)
```

## 🚀 Quick Start

### 1. Set up configuration

```powershell
# Copy the example configuration
Copy-Item deployment\config.example.json deployment\config.json

# Edit the config.json file with your server details
notepad deployment\config.json
```

### 2. Configure SSH

Ensure you have:
- SSH key pair set up (`ssh-keygen` if needed)
- Public key added to `~/.ssh/authorized_keys` on remote server
- SSH agent running with your key added

### 3. Test SSH connection manually

```powershell
ssh your_username@your-server.internal
```

### 4. Deploy!

```powershell
# Simple usage
.\deployment\deploy.ps1
```

The script exclusively uses `config.json` for configuration.

## 🔧 Configuration Example

Edit `deployment\config.json`:

```json
{
    "remoteUser": "deploy",
    "remoteHost": "data-platform.internal",
    "remotePath": "/opt/foss-data-platform",
    "sshPort": 22,
    "dockerComposeFile": "docker-compose.yml"
}
```

## 🔐 Security Notes

- `config.json` is in `.gitignore` - your credentials won't be committed
- Use SSH keys for password-less authentication
- Keep your private key secure
- Only run deployment from trusted machines

## 📋 Deployment Workflow

1. **Pre-flight checks**
   - Verify clean git working tree
   - Detect current branch
   - Test SSH connection

2. **Remote execution**
   - `cd /path/to/repo`
   - `git fetch origin`
   - `git checkout your-branch`
   - `git pull origin your-branch`
   - `docker compose pull`
   - `docker compose up -d --remove-orphans`

3. **Completion**
   - Success/failure reporting
   - Color-coded output

## 🎯 Requirements

- ✅ PowerShell (built into Windows)
- ✅ Git in PATH
- ✅ SSH client (OpenSSH) in PATH
- ✅ VPN connection established
- ✅ SSH key authentication configured

## 💡 Tips

- **VPN first**: Always connect to VPN before running deployment
- **Test manually**: Verify SSH works before first deployment
- **Monitor**: Check server during first deployment
- **Logs**: Deployment output shows exactly what commands are run

## 🚫 Troubleshooting

**SSH connection fails:**
- Check VPN connection
- Test manual SSH: `ssh user@host`
- Verify SSH keys are added to agent: `ssh-add -l`

**Git issues:**
- Make sure branch exists on remote
- Check remote repository is accessible

**Docker issues:**
- Verify Docker is installed on remote
- Check Docker Compose file exists
- Ensure user has Docker permissions

## 📚 Documentation

- [Complete Documentation](DEPLOYMENT.md)
- [Implementation Summary](DEPLOYMENT_SUMMARY.md)
- [PowerShell Script](deploy.ps1)

Ready to deploy? Just run:
```powershell
.\deployment\deploy.ps1
```