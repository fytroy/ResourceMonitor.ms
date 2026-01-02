<#
.SYNOPSIS
    Part A: Background Resource Monitor (Headless)
.DESCRIPTION
    - Checks CPU, RAM, Disk.
    - Sends Emails via SMTP.
    - Logs to Windows Event Viewer.
    - NO GUI/Pop-ups (Safe for background Service/Task).
.NOTES
    Requires: Administrator privileges for Event Log source creation
    Version: 1.1
    Updated: 2026-01-02
#>

# Requires -RunAsAdministrator (for Event Log source creation)

# --- CONFIGURATION ---
$CpuThreshold     = 90
$MemThreshold     = 10  # Percent free memory
$DiskThreshold    = 10  # Percent free disk space
$ComputerName     = $env:COMPUTERNAME

# --- EMAIL SETTINGS ---
# UPDATE THESE VALUES BEFORE ENABLING EMAIL
$EnableEmail      = $false  # Set to $true after configuring email settings
$EmailTo          = "admin@example.com"
$EmailFrom        = "monitor@example.com"
$SmtpServer       = "smtp.example.com"
$SmtpPort         = 25  # Common ports: 25, 587, 465
# If your SMTP needs credentials, you will need a more advanced setup using PSCredential

# Validate email configuration
if ($EnableEmail) {
    if ($EmailTo -eq "admin@example.com" -or $SmtpServer -eq "smtp.example.com") {
        Write-Warning "Email is enabled but using default settings. Please configure email settings."
        $EnableEmail = $false
    }
}

# --- LOGGING FUNCTION ---
function Log-Alert {
    param ([string]$Subject, [string]$Body)

    # 1. Write to Event Viewer (Source: ServerMonitor)
    $logSource = "ServerMonitor"
    if (-not ([System.Diagnostics.EventLog]::SourceExists($logSource))) {
        New-EventLog -LogName Application -Source $logSource
    }
    Write-EventLog -LogName Application -Source $logSource -EntryType Warning -EventId 1001 -Message "$Subject`n$Body"

    # 2. Send Email
    if ($EnableEmail) {
        try {
            $mailParams = @{
                To          = $EmailTo
                From        = $EmailFrom
                Subject     = "ALERT: $ComputerName - $Subject"
                Body        = $Body
                SmtpServer  = $SmtpServer
                Port        = $SmtpPort
            }
            Send-MailMessage @mailParams
        } catch {
            Write-EventLog -LogName Application -Source $logSource -EntryType Error -EventId 1002 -Message "Failed to send email alert: $($_.Exception.Message)"
        }
    }
}

# --- CHECKS ---

# 1. CPU
try {
    $cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average
    $cpuLoad = [math]::Round($cpu.Average)
    if ($cpuLoad -gt $CpuThreshold) { 
        Log-Alert "High CPU" "CPU usage is at $cpuLoad% (Threshold: $CpuThreshold%)"
    }
} catch {
    Write-Warning "Failed to check CPU: $($_.Exception.Message)"
}

# 2. Memory
try {
    $os = Get-CimInstance Win32_OperatingSystem
    $freeMem = $os.FreePhysicalMemory; $totalMem = $os.TotalVisibleMemorySize
    $percFree = [math]::Round(($freeMem / $totalMem) * 100, 2)
    $usedPercent = [math]::Round(100 - $percFree, 2)
    if ($percFree -lt $MemThreshold) { 
        Log-Alert "Low Memory" "Memory is at $usedPercent% used ($percFree% free, Threshold: $MemThreshold% free)"
    }
} catch {
    Write-Warning "Failed to check memory: $($_.Exception.Message)"
}

# 3. Disk
try {
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($d in $disks) {
        if ($d.Size -gt 0) {
            $percFree = [math]::Round(($d.FreeSpace / $d.Size) * 100, 2)
            $freeGB = [math]::Round($d.FreeSpace / 1GB, 2)
            if ($percFree -lt $DiskThreshold) { 
                Log-Alert "Low Disk Space ($($d.DeviceID))" "Drive $($d.DeviceID) is at $percFree% free ($freeGB GB available, Threshold: $DiskThreshold%)"
            }
        }
    }
} catch {
    Write-Warning "Failed to check disk space: $($_.Exception.Message)"
}