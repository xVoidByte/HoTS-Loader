# ~ HoTS Loader ~
# Run as administrator and hide console
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# HIDE CONSOLE WINDOW
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationFramework

# CONFIGURATION 
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$configFile = Join-Path $scriptPath "config.xml"
$accountsFile = Join-Path $scriptPath "accounts.csv"
$iconFile = Join-Path $scriptPath "icon.ico"
$desktopShortcut = Join-Path ([Environment]::GetFolderPath("Desktop")) "HoTS Loader.lnk"

# REGIONS 
$regions = @{
    "1" = "us.actual.battle.net"
    "2" = "eu.actual.battle.net" 
    "3" = "kr.actual.battle.net"
    "NA" = "us.actual.battle.net"
    "EU" = "eu.actual.battle.net"
    "KR" = "kr.actual.battle.net"
}

# DARK THEME COLORS 
$darkBg = "#1e1e1e"
$darkPanel = "#2d2d30"
$darkText = "#d4d4d4"
$darkBorder = "#3e3e42"
$accentColor = "#007acc"
$buttonBg = "#0e639c"
$buttonHover = "#1177bb"

# GUI OUTPUT CONTROL 
$global:guiOutput = $null
$global:accounts = @()
$global:mainForm = $null

function Add-GuiOutput {
    param([string]$text, [string]$color = "White")
    if ($global:guiOutput -ne $null) {
        $global:guiOutput.SelectionColor = [System.Drawing.ColorTranslator]::FromHtml($color)
        $global:guiOutput.AppendText("$text`n")
        $global:guiOutput.ScrollToCaret()
    }
}

# GET CONFIG 
function Get-Config {
    try {
        [xml]$config = Get-Content $configFile
        return @{
            GamePath = $config.config.GamePath
        }
    } catch {
        return @{
            GamePath = "F:\HotS\Heroes of the Storm"
        }
    }
}

# LOAD ACCOUNTS 
function Get-Accounts {
    try {
        if (Test-Path $accountsFile) {
            return Import-Csv $accountsFile
        }
        return @()
    } catch {
        return @()
    }
}

# LAUNCH GAME 
function Launch-Game {
    param(
        [string]$email,
        [string]$password,
        [string]$region,
        [string]$friendlyName
    )
    
    $config = Get-Config
    $gamePath = $config.GamePath
    
    $gameExe = Join-Path $gamePath "Support64\HeroesSwitcher_x64.exe"
    $workingDir = Join-Path $gamePath "Support64"
    
    if (!(Test-Path $gameExe)) {
        Add-GuiOutput "ERROR: Game executable not found: $gameExe" "Red"
        return $false
    }
    
    Add-GuiOutput "=== LAUNCH DETAILS ===" "Cyan"
    Add-GuiOutput "Account: $email" "Yellow"
    Add-GuiOutput "Region: $region" "Yellow"
    Add-GuiOutput "Executable: $gameExe" "Yellow"
    Add-GuiOutput "Working Directory: $workingDir" "Yellow"
    
    try {
        $arguments = "-launch"
        Add-GuiOutput "Arguments: $arguments" "Yellow"
        Add-GuiOutput "Launching game..." "Green"
        
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $gameExe
        $psi.Arguments = $arguments
        $psi.WorkingDirectory = $workingDir
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        
        $process = [System.Diagnostics.Process]::Start($psi)
        
        Add-GuiOutput "Process started with PID: $($process.Id)" "Green"
        
        Start-Sleep 3
        
        if ($process.HasExited) {
            Add-GuiOutput "Process exited with code: $($process.ExitCode)" "Red"
            return $false
        } else {
            Add-GuiOutput "Game is running successfully!" "Green"
            
            if ($friendlyName) {
                Start-Sleep 2
                Rename-Window -processId $process.Id -newTitle "HoTS - $friendlyName"
            }
            return $true
        }
    } catch {
        Add-GuiOutput "Launch failed: $_" "Red"
        return $false
    }
}

# RENAME WINDOW 
function Rename-Window {
    param([int]$processId, [string]$newTitle)
    
    try {
        Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WindowRenamer {
    [DllImport("user32.dll")]
    public static extern bool SetWindowText(IntPtr hWnd, string lpString);
}
"@
        
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($process -and $process.MainWindowHandle -ne [IntPtr]::Zero) {
            [WindowRenamer]::SetWindowText($process.MainWindowHandle, $newTitle)
            Add-GuiOutput "Window renamed to: $newTitle" "Green"
        }
    } catch {
        Add-GuiOutput "Could not rename window: $_" "Yellow"
    }
}

# CREATE DESKTOP SHORTCUT 
function Create-DesktopShortcut {
    try {
        if (!(Test-Path $desktopShortcut)) {
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($desktopShortcut)
            $Shortcut.TargetPath = "powershell.exe"
            $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -NoProfile -NonInteractive -File `"$PSCommandPath`""
            $Shortcut.WorkingDirectory = $scriptPath
            
            if (Test-Path $iconFile) {
                $Shortcut.IconLocation = $iconFile
            } else {
                $Shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,21"
            }
            
            $Shortcut.Save()
            Add-GuiOutput "Desktop shortcut created: HoTS Loader" "Green"
            return $true
        }
        return $false
    } catch {
        Add-GuiOutput "Could not create desktop shortcut: $_" "Yellow"
        return $false
    }
}

# MAIN GUI 
function Show-GUI {
    # Create main form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Heroes of the Storm Launcher"
    $form.Size = New-Object System.Drawing.Size(800, 700)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.BackColor = [System.Drawing.ColorTranslator]::FromHtml($darkBg)
    $global:mainForm = $form
    
    # Title
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "HEROES OF THE STORM LOADER"
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($accentColor)
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(740, 40)
    $titleLabel.TextAlign = "MiddleCenter"
    $form.Controls.Add($titleLabel)
    
    # Accounts panel
    $accountsPanel = New-Object System.Windows.Forms.Panel
    $accountsPanel.Location = New-Object System.Drawing.Point(20, 80)
    $accountsPanel.Size = New-Object System.Drawing.Size(740, 200)
    $accountsPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml($darkPanel)
    $accountsPanel.BorderStyle = "FixedSingle"
    $form.Controls.Add($accountsPanel)
    
    $accountsLabel = New-Object System.Windows.Forms.Label
    $accountsLabel.Text = "ACCOUNTS"
    $accountsLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $accountsLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($darkText)
    $accountsLabel.Location = New-Object System.Drawing.Point(10, 10)
    $accountsLabel.Size = New-Object System.Drawing.Size(200, 25)
    $accountsPanel.Controls.Add($accountsLabel)
    
    # Accounts list
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10, 40)
    $listBox.Size = New-Object System.Drawing.Size(720, 130)
    $listBox.Font = New-Object System.Drawing.Font("Consolas", 10)
    $listBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml($darkBg)
    $listBox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($darkText)
    $listBox.BorderStyle = "FixedSingle"
    $accountsPanel.Controls.Add($listBox)
    
    # Output panel
    $outputPanel = New-Object System.Windows.Forms.Panel
    $outputPanel.Location = New-Object System.Drawing.Point(20, 300)
    $outputPanel.Size = New-Object System.Drawing.Size(740, 280)
    $outputPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml($darkPanel)
    $outputPanel.BorderStyle = "FixedSingle"
    $form.Controls.Add($outputPanel)
    
    $outputLabel = New-Object System.Windows.Forms.Label
    $outputLabel.Text = "OUTPUT"
    $outputLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $outputLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($darkText)
    $outputLabel.Location = New-Object System.Drawing.Point(10, 10)
    $outputLabel.Size = New-Object System.Drawing.Size(200, 25)
    $outputPanel.Controls.Add($outputLabel)
    
    # Output textbox
    $outputBox = New-Object System.Windows.Forms.RichTextBox
    $outputBox.Location = New-Object System.Drawing.Point(10, 40)
    $outputBox.Size = New-Object System.Drawing.Size(720, 230)
    $outputBox.Font = New-Object System.Drawing.Font("Consolas", 9)
    $outputBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml($darkBg)
    $outputBox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($darkText)
    $outputBox.BorderStyle = "FixedSingle"
    $outputBox.ReadOnly = $true
    $outputBox.ScrollBars = "Vertical"
    $global:guiOutput = $outputBox
    $outputPanel.Controls.Add($outputBox)
    
    # Button panel
    $buttonPanel = New-Object System.Windows.Forms.Panel
    $buttonPanel.Location = New-Object System.Drawing.Point(20, 590)
    $buttonPanel.Size = New-Object System.Drawing.Size(740, 60)
    $buttonPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml($darkBg)
    $form.Controls.Add($buttonPanel)
    
    # Button style function
    function Style-Button {
        param($button)
        $button.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $button.FlatStyle = "Flat"
        $button.FlatAppearance.BorderColor = [System.Drawing.ColorTranslator]::FromHtml($darkBorder)
        $button.BackColor = [System.Drawing.ColorTranslator]::FromHtml($buttonBg)
        $button.ForeColor = [System.Drawing.Color]::White
        $button.FlatAppearance.MouseOverBackColor = [System.Drawing.ColorTranslator]::FromHtml($buttonHover)
        $button.Size = New-Object System.Drawing.Size(240, 40)
    }
    
    # Launch button
    $launchButton = New-Object System.Windows.Forms.Button
    $launchButton.Text = "LAUNCH"
    $launchButton.Location = New-Object System.Drawing.Point(10, 10)
    Style-Button $launchButton
    $launchButton.Add_Click({
        if ($listBox.SelectedIndex -ge 0) {
            $account = $global:accounts[$listBox.SelectedIndex]
            $regionServer = if ($regions.ContainsKey($account.Region)) { $regions[$account.Region] } else { $account.Region }
            Add-GuiOutput "Launching $($account.FriendlyName)..." "Yellow"
            Launch-Game -email $account.Email -password $account.Password -region $regionServer -friendlyName $account.FriendlyName
        } else {
            Add-GuiOutput "Please select an account first" "Orange"
        }
    })
    $buttonPanel.Controls.Add($launchButton)
    
    # Refresh button
    $refreshButton = New-Object System.Windows.Forms.Button
    $refreshButton.Text = "REFRESH"
    $refreshButton.Location = New-Object System.Drawing.Point(260, 10)
    Style-Button $refreshButton
    $refreshButton.Add_Click({
        Load-Accounts
    })
    $buttonPanel.Controls.Add($refreshButton)
    
    # Exit button
    $exitButton = New-Object System.Windows.Forms.Button
    $exitButton.Text = "EXIT"
    $exitButton.Location = New-Object System.Drawing.Point(510, 10)
    Style-Button $exitButton
    $exitButton.Add_Click({
        $form.Close()
    })
    $buttonPanel.Controls.Add($exitButton)
    
    # Load accounts function
    function Load-Accounts {
        $global:accounts = Get-Accounts
        $listBox.Items.Clear()
        
        if ($global:accounts.Count -eq 0) {
            $listBox.Items.Add("No accounts found. Check accounts.csv")
            Add-GuiOutput "No accounts loaded from accounts.csv" "Orange"
        } else {
            foreach ($acc in $global:accounts) {
                $listBox.Items.Add("$($acc.FriendlyName) | $($acc.Email) | Region: $($acc.Region)")
            }
            $listBox.SelectedIndex = 0
            Add-GuiOutput "Loaded $($global:accounts.Count) account(s)" "Green"
        }
    }
    
    # Initial load
    Load-Accounts
    
    # Create shortcut on first run
    if (!(Test-Path $desktopShortcut)) {
        Add-GuiOutput "Creating desktop shortcut..." "Yellow"
        Create-DesktopShortcut
    }
    
    Add-GuiOutput "HoTS Launcher ready" "Green"
    
    # Show form
    [void]$form.ShowDialog()
}

# MAIN 
# Always show GUI
Show-GUI