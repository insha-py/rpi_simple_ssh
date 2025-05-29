# Multi-SSH Terminal Launcher

This repository contains scripts to easily open multiple terminal windows for SSH connections to different devices on your network. Two versions are provided:

- **`multi_ssh.ps1`** - PowerShell script for Windows
- **`multi_ssh.sh`** - Bash script for Linux, macOS, and WSL

## Features

- 🖥️ **Multiple Terminal Windows**: Opens separate terminal windows for each SSH connection
- 📋 **Interactive Menu**: Choose specific devices or connect to all at once
- 🏷️ **Custom Window Titles**: Each terminal window is labeled with the device name
- 🔧 **Easy Configuration**: Simple arrays to define your network devices
- 🎨 **Colored Output**: Clear visual feedback with colored text
- 🔄 **Cross-Platform**: Works on Windows, Linux, macOS, and WSL

## Quick Start

### Windows (PowerShell)

1. **Edit the device configuration** in `multi_ssh.ps1`:
   ```powershell
   $devices = @(
       @{
           name = "Your Router"
           ip = "192.168.1.1"
           user = "admin"
           port = 22
       },
       @{
           name = "Your Server"
           ip = "192.168.1.100"
           user = "username"
           port = 22
       }
   )
   ```

2. **Run the script**:
   ```powershell
   .\multi_ssh.ps1
   ```

### Linux/macOS/WSL (Bash)

1. **Make the script executable**:
   ```bash
   chmod +x multi_ssh.sh
   ```

2. **Edit the device configuration** in `multi_ssh.sh`:
   ```bash
   declare -A devices=(
       ["Router"]="admin@192.168.1.1:22"
       ["Server"]="username@192.168.1.100:22"
   )
   ```

3. **Run the script**:
   ```bash
   ./multi_ssh.sh
   ```

## Configuration

### PowerShell Script Configuration

Edit the `$devices` array in `multi_ssh.ps1`:

```powershell
$devices = @(
    @{
        name = "Device Name"        # Friendly name for the device
        ip = "192.168.1.xxx"       # IP address
        user = "username"          # SSH username
        port = 22                  # SSH port (usually 22)
    }
)
```

### Bash Script Configuration

Edit the `devices` associative array in `multi_ssh.sh`:

```bash
declare -A devices=(
    ["DeviceName"]="username@192.168.1.xxx:port"
)
```

## Usage Examples

### Example Device Configurations

**Home Network Setup:**
```powershell
# PowerShell
$devices = @(
    @{ name = "Router"; ip = "192.168.1.1"; user = "admin"; port = 22 },
    @{ name = "NAS"; ip = "192.168.1.5"; user = "admin"; port = 22 },
    @{ name = "Raspberry Pi"; ip = "192.168.1.20"; user = "pi"; port = 22 },
    @{ name = "Home Server"; ip = "192.168.1.100"; user = "user"; port = 22 }
)
```

```bash
# Bash
declare -A devices=(
    ["Router"]="admin@192.168.1.1:22"
    ["NAS"]="admin@192.168.1.5:22"
    ["RaspberryPi"]="pi@192.168.1.20:22"
    ["HomeServer"]="user@192.168.1.100:22"
)
```

**Office Network Setup:**
```powershell
# PowerShell
$devices = @(
    @{ name = "Web Server"; ip = "10.0.1.10"; user = "deploy"; port = 22 },
    @{ name = "Database Server"; ip = "10.0.1.11"; user = "dbadmin"; port = 22 },
    @{ name = "Load Balancer"; ip = "10.0.1.5"; user = "admin"; port = 2222 }
)
```

## Prerequisites

### Windows
- PowerShell (built into Windows)
- SSH client (available in Windows 10/11 by default, or install OpenSSH)
- Optional: Windows Terminal (for better experience)

### Linux
- Bash shell
- SSH client (`openssh-client`)
- Terminal emulator (gnome-terminal, konsole, or xterm)

### macOS
- Bash shell (built-in)
- SSH client (built-in)
- Terminal app (built-in)

### WSL (Windows Subsystem for Linux)
- WSL enabled with a Linux distribution
- SSH client

## Troubleshooting

### Common Issues

1. **"ssh: command not found"**
   - **Windows**: Install OpenSSH client feature or use Git Bash
   - **Linux**: Install openssh-client: `sudo apt install openssh-client`

2. **"Permission denied (publickey)"**
   - Set up SSH key authentication or use password authentication
   - Ensure your SSH keys are properly configured

3. **"Connection refused"**
   - Check if SSH service is running on the target device
   - Verify the IP address and port number
   - Check firewall settings

4. **PowerShell execution policy error**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

### Terminal Emulator Detection

The bash script automatically detects and uses available terminal emulators:
- **Linux**: gnome-terminal, konsole, xterm
- **macOS**: Terminal.app
- **Windows/Git Bash**: mintty

## Security Considerations

1. **SSH Key Authentication**: Use SSH keys instead of passwords for better security
2. **SSH Config**: Consider using `~/.ssh/config` for connection settings
3. **Network Security**: Ensure your network devices are properly secured
4. **Script Security**: Don't hardcode passwords in the scripts

### SSH Key Setup Example

Generate SSH keys:
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Copy public key to devices:
```bash
ssh-copy-id username@device_ip
```

## Advanced Usage

### Using SSH Config File

Instead of hardcoding connection details, you can use SSH config files:

Create `~/.ssh/config`:
```
Host router
    HostName 192.168.1.1
    User admin
    Port 22

Host server1
    HostName 192.168.1.10
    User user
    Port 22
```

Then modify your device arrays to use config names:
```bash
# Bash version
declare -A devices=(
    ["Router"]="router"
    ["Server1"]="server1"
)
```

### Custom SSH Options

You can modify the SSH commands in the scripts to include additional options:
```bash
ssh_command="ssh -o ConnectTimeout=10 -o ServerAliveInterval=60 -p $port $user_host"
```

## Contributing

Feel free to contribute improvements, bug fixes, or additional features:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source and available under the MIT License.

## Support

If you encounter issues or have questions:
1. Check the troubleshooting section above
2. Verify your network configuration
3. Test SSH connections manually first
4. Open an issue with detailed information about your setup 