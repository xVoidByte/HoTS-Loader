# HoTS Direct Launcher

[![Video Preview](https://i.ibb.co/6cXfzy1M/Screenshot-2026-01-06-181523.png)](https://www.youtube.com/watch?v=4BO0eQdFf5w)


Bypass Battle.net completely and launch Heroes of the Storm directly from the loader, no need to wait for b.net to run game update checks, no background processes eating your RAM/CPU.

**Why this project?**  
Battle.net launcher is pointless, it runs multiple services, hogs memory, and forces updates.  
The loader cuts out the middleman - launches HoTS directly using the game's own executable with proper authentication for faster startup and less resource usage.

**How it works?**  

Uses HoTS's built-in HeroesSwitcher with direct launch parameters.  
The script finds your game installation, handles authentication through command line arguments, and starts the game without loading Battle.net services.

## Installation

1. [Download latest release](https://github.com/xVoidByte/HoTS-Loader/releases/latest) and extract to any folder
2. Right-click `HoTSLoader.ps1` -> Properties -> Check "Unblock" -> Apply (unless already unblocked)

## First Run (Required)

**Option 1 - via PowerShell:**
```powershell
cd "C:\Your\Path\To\HoTS-Loader"
powershell -ExecutionPolicy Bypass -File HoTSLoader.ps1
```

**Option 2 - via Terminal from project root folder:**  
Navigate to root folder -> Shift + Right Click -> "Open PowerShell window here" -> Run:
```powershell
powershell -ExecutionPolicy Bypass -File HoTSLoader.ps1
```

The script creates a desktop shortcut automatically on first run.

## Configuration

### Game Path (config.xml)
Open `config.xml` in any text editor:
```xml
<?xml version="1.0"?>
<config>
    <GamePath>C:\Program Files\Heroes of the Storm</GamePath>
</config>
```
Change the path to your HoTS installation folder.

### Accounts (accounts.csv)
Open `accounts.csv` in any text editor:
```
Email,FriendlyName,Region
your@email.com,Main Account,EU
```

**Fields:**
- **Email** - Your Battle.net email
- **FriendlyName** - Display name in launcher
- **Region** - Your game region (NA/EU/KR)

**Regions:**
- **NA** - Americas (us.actual.battle.net)
- **EU** - Europe (eu.actual.battle.net)
- **KR** - Asia (kr.actual.battle.net)

## Requirements

- Windows OS
- PowerShell/Terminal
- Heroes of the Storm installed
- Administrative rights (in case of handle errors)

## Current Limitations

- Region selection in GUI - HoTS defaults to Americas region
- Manual username/password entry required on first login

_Future updates: automate region selection based on config file, login via credentials from config file_

## Support

Like this project? Buy me a coffee: https://ko-fi.com/xvoidbyte

## Issues/Features: 

Create a GitHub issue with detailed information.
