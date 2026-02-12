# PowerShell Profile Configuration

A comprehensive PowerShell profile configuration that enhances your command-line experience with modern tools, productivity shortcuts, and beautiful theming. Based on Chris Titus Tech's PowerShell profile with customizations and improvements.

**Bash users**: A bash counterpart is included so your Linux/macOS/WSL terminal can match the same look and feel. See [Bash Installation](#-bash-installation) below.

## 📁 Project Structure

```
├── windows/           # Windows / PowerShell
│   ├── setup.ps1      # PowerShell installer
│   ├── profile.ps1    # User override template (theme, debug, etc.)
│   └── Microsoft.PowerShell_profile.ps1   # Reference copy of main profile
├── linux/             # Linux / macOS / WSL / Bash
│   ├── setup.sh       # Bash installer
│   ├── bashrc         # Main bash profile
│   └── profile.bash   # User override template
├── my_layout.omp.json # Shared Oh My Posh theme (used by both)
└── README.md
```

## 🚀 Quick Installation

### One-Line Run (copy & paste)

**Windows (PowerShell as Administrator):**
```powershell
irm "https://github.com/ChristianG-Solideon/Powershell-setup/raw/main/windows/setup.ps1" | iex
```

**Linux / macOS / WSL:**
```bash
curl -sL "https://github.com/ChristianG-Solideon/Powershell-setup/raw/main/linux/setup.sh" | bash
```

---

### From a local clone

**Windows**

From the repo root, run:

```powershell
.\windows\setup.ps1
```

**Linux / macOS / WSL**

```bash
git clone <your-repo-url> powershell-setup && cd powershell-setup
chmod +x linux/setup.sh && ./linux/setup.sh
```

Or from an existing clone:

```bash
./linux/setup.sh
```

The script installs Oh My Posh, zoxide, eza (ls with icons), Nerd Fonts, and configures your bash profile. Restart your terminal or run `source ~/.bashrc`.

## ✨ Features

### 🔄 Auto-Update System
- **Profile Updates**: Automatically checks for and installs profile updates every 7 days
- **PowerShell Updates**: Automatically checks for and installs PowerShell updates
- **Debug Mode**: Skip auto-updates during development with debug mode

### 🎨 Enhanced Terminal Experience
- **Oh My Posh Integration**: Beautiful terminal prompt with custom theme
- **Terminal Icons**: File and folder icons for better visual navigation
- **PSReadLine**: Enhanced command-line editing with syntax highlighting
- **Zoxide Integration**: Smart directory jumping (`z` command)

### 🛠️ Productivity Tools
- **Unix-like Aliases**: Familiar commands like `ls`, `grep`, `which`, `head`, `tail`
- **Git Shortcuts**: Quick git operations (`gs`, `ga`, `gc`, `gpush`, `gpull`)
- **File Operations**: Enhanced file management (`la`, `ll`, `mkcd`, `nf`)
- **System Utilities**: Process management, system info, networking tools

### 🎯 Custom Functions
- **WinUtil Integration**: Quick access to Windows utility scripts
- **Clipboard Tools**: Copy/paste utilities (`cpy`, `pst`)
- **Network Tools**: DNS flush, public IP lookup, file sharing (`hb`)
- **Development Helpers**: File search, text replacement, process management

## 🔧 Customization

This profile supports extensive customization through override functions and variables. Create a `profile.ps1` file in your PowerShell directory to customize:

### Override Variables
```powershell
$debug_Override = $true                    # Enable debug mode
$repo_root_Override = "your-fork-url"      # Use your own fork
$timeFilePath_Override = "custom-path"     # Custom update tracking file
$updateInterval_Override = 14              # Custom update interval (days)
$EDITOR_Override = "code"                  # Set preferred editor
```

### Override Functions
```powershell
function Update-Profile_Override {
    # Your custom update logic
}

function Get-Theme_Override {
    # Your custom theme configuration
}

function Clear-Cache_Override {
    # Your custom cache clearing logic
}
```

### Bash Customization

Edit `~/.config/bash/profile.bash` (or `$XDG_CONFIG_HOME/bash/profile.bash`) to add your own aliases and overrides:

```bash
# Custom aliases
alias mycommand='something'

# Custom theme path
export OMP_CONFIG="$HOME/.config/bash/my_layout.omp.json"
```

## 📋 Available Commands

### Git Shortcuts
| Command | Description |
|---------|-------------|
| `gs` | git status |
| `ga` | git add . |
| `gc <message>` | git commit -m |
| `gpush` | git push |
| `gpull` | git pull |
| `gcom <message>` | git add . && git commit -m |
| `lazyg <message>` | git add . && git commit -m && git push |

### File Operations
| Command | Description |
|---------|-------------|
| `la` | List files with formatting |
| `ll` | List all files (including hidden) |
| `mkcd <dir>` | Create and change to directory |
| `nf <name>` | Create new file |
| `touch <file>` | Create empty file |
| `unzip <file>` | Extract zip file |

### System Utilities
| Command | Description |
|---------|-------------|
| `sysinfo` | Display system information |
| `uptime` | Show system uptime |
| `flushdns` | Clear DNS cache |
| `Get-PubIP` | Get public IP address |
| `admin` | Run command as administrator |

### Development Tools
| Command | Description |
|---------|-------------|
| `ep` | Edit PowerShell profile |
| `reload-profile` | Reload current profile |
| `winutil` | Run WinUtil (full release) |
| `winutildev` | Run WinUtil (development) |
| `hb <file>` | Upload file to hastebin |

### Navigation
| Command | Description |
|---------|-------------|
| `docs` | Go to Documents folder |
| `dtop` | Go to Desktop folder |
| `z <path>` | Smart directory jumping (zoxide) |

## 📦 Requirements

### PowerShell
- **PowerShell 5.1+** or **PowerShell Core 6+**
- **Windows Terminal** (recommended)
- **Oh My Posh** (auto-installed)
- **Terminal-Icons** module (auto-installed)
- **Zoxide** (auto-installed via winget)

### Bash
- **Bash 4+**
- **curl**, **unzip** (for setup)
- **Oh My Posh** (auto-installed)
- **eza** (auto-installed where available; ls with icons)
- **zoxide** (auto-installed)

## 🎨 Theme Configuration

Both PowerShell and Bash use the same Oh My Posh theme (`my_layout.omp.json`) for a consistent look:
- Clean, modern design with diamond segments
- Git status indicators
- Custom color palette
- User/host name mapping
- Virtual environment support

## 🔍 Debug Mode (PowerShell)

Enable debug mode to skip auto-updates and see detailed information:

```powershell
$debug_Override = $true
```

In debug mode:
- Auto-updates are disabled
- Debug messages are displayed
- Profile changes won't be overwritten

## 📚 Help

**PowerShell**: Run `Show-Help` to display all commands.

**Bash**: Run `show_help` to display all commands.

## 🤝 Contributing

This profile is based on Chris Titus Tech's PowerShell profile. To contribute:

1. Fork the repository
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## 📄 License

This project is open source. Please refer to the original Chris Titus Tech repository for licensing information.

## 🙏 Credits

- **Chris Titus Tech** - Original PowerShell profile creator
- **Oh My Posh** - Terminal prompt theming
- **Terminal Icons** - File/folder icons
- **Zoxide** - Smart directory jumping

---

**Note**: This profile automatically updates itself. If you want to make permanent changes, use the override system described in the Customization section.
