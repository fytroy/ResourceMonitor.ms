<#
.SYNOPSIS
    Part B: Interactive Tray App (Visual)
.DESCRIPTION
    - Sits in System Tray.
    - Shows Balloon Tip Pop-ups on threshold breach.
    - Runs in a loop until user exits via Tray Icon.
.NOTES
    Version: 1.1
    Updated: 2026-01-02
    Requires: PowerShell 5.1+ with Windows Forms
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CONFIGURATION ---
$CpuThreshold  = 90   # Alert if CPU usage exceeds this percentage
$MemThreshold  = 10   # Alert if free memory drops below this percentage
$DiskThreshold = 10   # Alert if free disk space drops below this percentage
$CheckInterval = 60000 # Check every 60 seconds (60000 milliseconds)

# --- TRAY ICON SETUP ---
$notify = New-Object System.Windows.Forms.NotifyIcon
$notify.Text = "System Monitor: Active"
try {
    # Try to grab the PowerShell icon
    $notify.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -Id $pid).Path)
} catch {
    # Fallback to a standard system icon if extraction fails
    $notify.Icon = [System.Drawing.SystemIcons]::Application
}
$notify.Visible = $true

# Context Menu with additional options
$ctx = New-Object System.Windows.Forms.ContextMenu
$itemStatus = $ctx.MenuItems.Add("Status: Monitoring")
$itemStatus.Enabled = $false  # Just for display
$ctx.MenuItems.Add("-")  # Separator
$itemCheckNow = $ctx.MenuItems.Add("Check Now")
$itemCheckNow.add_Click({ Invoke-Check })
$itemExit = $ctx.MenuItems.Add("Exit Monitor")
$itemExit.add_Click({
    $notify.Visible = $false
    $timer.Stop()
    $appCtx.ExitThread()
})
$notify.ContextMenu = $ctx

# --- CHECK LOGIC ---
function Invoke-Check {
    $msg = ""
    $alert = $false

    try {
        # CPU
        $cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
        $cpuRounded = [math]::Round($cpu)
        if ($cpuRounded -gt $CpuThreshold) { 
            $msg += "CPU High: $cpuRounded% (Threshold: $CpuThreshold%)`n"
            $alert = $true 
        }

        # RAM
        $os = Get-CimInstance Win32_OperatingSystem
        $ramFree = [math]::Round(($os.FreePhysicalMemory / $os.TotalVisibleMemorySize) * 100, 2)
        if ($ramFree -lt $MemThreshold) { 
            $msg += "RAM Low: $ramFree% Free (Threshold: $MemThreshold%)`n"
            $alert = $true 
        }

        # Disk (C: only for brevity in pop-up)
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
        if ($disk -and $disk.Size -gt 0) {
            $diskFree = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
            $diskFreeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            if ($diskFree -lt $DiskThreshold) { 
                $msg += "Disk C: Low: $diskFree% Free ($diskFreeGB GB, Threshold: $DiskThreshold%)"
                $alert = $true 
            }
        }

        if ($alert) {
            $notify.BalloonTipTitle = "⚠️ System Alert"
            $notify.BalloonTipText = $msg.TrimEnd()
            $notify.BalloonTipIcon = "Warning"
            $notify.ShowBalloonTip(10000) # Show for 10 seconds
        }
    } catch {
        $notify.BalloonTipTitle = "❌ Monitor Error"
        $notify.BalloonTipText = "Failed to check system resources: $($_.Exception.Message)"
        $notify.BalloonTipIcon = "Error"
        $notify.ShowBalloonTip(5000)
    }
}

# --- TIMER LOOP ---
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = $CheckInterval
$timer.add_Tick({ Invoke-Check })
$timer.Start()

# Initial Check
Invoke-Check

# Show startup notification
$notify.BalloonTipTitle = "✓ System Monitor Started"
$notify.BalloonTipText = "Monitoring CPU, RAM, and Disk every $($CheckInterval/1000) seconds"
$notify.BalloonTipIcon = "Info"
$notify.ShowBalloonTip(3000)

# Cleanup handler
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    if ($notify) { $notify.Dispose() }
    if ($timer) { $timer.Dispose() }
}

# Start App Loop
$appCtx = New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appCtx)