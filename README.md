 Resource Monitor for Windows

A comprehensive PowerShell-based system monitoring solution with two complementary components: a headless background monitor and an interactive system tray application.

 Overview

This project provides real-time monitoring of critical system resources (CPU, Memory, Disk) with customizable thresholds and multiple notification methods.

 Components

1. BackgroundMonitor.ps1 - Headless background service
   - Logs alerts to Windows Event Viewer
   - Sends email notifications via SMTP
   - Suitable for scheduled tasks or services
   - No GUI components (safe for background execution)

2. TrayMonitor.ps1 - Interactive system tray application
   - Visual balloon tip notifications
   - System tray icon with context menu
   - Manual "Check Now" option
   - Real-time monitoring with visual feedback

 Features

- ✅ CPU Usage Monitoring - Alert when CPU exceeds threshold
- ✅ Memory Monitoring - Alert when free RAM drops below threshold
- ✅ Disk Space Monitoring - Monitor all fixed drives or specific drives
- ✅ Event Log Integration - BackgroundMonitor logs to Windows Event Viewer
- ✅ Email Alerts - Optional SMTP email notifications (BackgroundMonitor)
- ✅ Balloon Notifications - Visual pop-ups in system tray (TrayMonitor)
- ✅ Configurable Thresholds - Easy customization of alert levels
- ✅ Error Handling - Robust error handling with fallback notifications

 Requirements

- Operating System: Windows 10/11 or Windows Server 2016+
- PowerShell: Version 5.1 or later
- Permissions: 
  - BackgroundMonitor requires Administrator privileges for Event Log source creation
  - TrayMonitor can run with standard user privileges

 Configuration

 BackgroundMonitor.ps1

Edit the configuration section at the top of the file:

```powershell
 Resource Thresholds
$CpuThreshold     = 90    Alert if CPU > 90%
$MemThreshold     = 10    Alert if free memory < 10%
$DiskThreshold    = 10    Alert if free disk space < 10%

 Email Settings (Optional)
$EnableEmail      = $false   Set to $true to enable email alerts
$EmailTo          = "admin@example.com"
$EmailFrom        = "monitor@example.com"
$SmtpServer       = "smtp.example.com"
$SmtpPort         = 25   Common ports: 25, 587, 465
```

Important: Before enabling email, update the email settings with your actual SMTP server details.

 TrayMonitor.ps1

Edit the configuration section:

```powershell
$CpuThreshold  = 90     Alert if CPU usage > 90%
$MemThreshold  = 10     Alert if free memory < 10%
$DiskThreshold = 10     Alert if free disk space < 10%
$CheckInterval = 60000  Check every 60 seconds (in milliseconds)
```

 Usage

 Running BackgroundMonitor

One-time execution:
```powershell
 Run as Administrator
.\BackgroundMonitor.ps1
```

Scheduled Task (Recommended):
```powershell
 Create a scheduled task to run every 5 minutes
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Path\To\BackgroundMonitor.ps1"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName "SystemResourceMonitor" -Action $action -Trigger $trigger -Principal $principal -Description "Monitors system resources and logs alerts"
```

 Running TrayMonitor

Interactive execution:
```powershell
 Run from PowerShell (standard user or administrator)
.\TrayMonitor.ps1
```

Auto-start with Windows:
1. Press `Win + R`, type `shell:startup`, and press Enter
2. Create a shortcut to the script with this target:
   ```
   powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Path\To\TrayMonitor.ps1"
   ```

Using the Tray Icon:
- Right-click the system tray icon to access the menu
- Select Check Now to perform an immediate system check
- Select Exit Monitor to stop monitoring and close the application

 Event Log Integration

BackgroundMonitor creates events in the Windows Event Viewer:

- Log: Application
- Source: ServerMonitor
- Event IDs:
  - `1001` - Resource threshold warning
  - `1002` - Email sending error

Viewing Events:
```powershell
 View recent alerts
Get-EventLog -LogName Application -Source ServerMonitor -Newest 10
```

Or use Event Viewer GUI: `eventvwr.msc` → Windows Logs → Application → Filter by Source "ServerMonitor"

 Troubleshooting

 BackgroundMonitor Issues

Event Log Source Creation Error:
- Ensure you're running PowerShell as Administrator
- The first run creates the "ServerMonitor" event source

Email Not Sending:
- Verify `$EnableEmail = $true`
- Check SMTP server settings (server, port, credentials)
- Ensure firewall allows outbound SMTP traffic
- Check Event Viewer (Event ID 1002) for detailed error messages

 TrayMonitor Issues

Script Doesn't Start:
- Check PowerShell execution policy: `Get-ExecutionPolicy`
- If restricted, run: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

No Balloon Tips Appearing:
- Check Windows notification settings (Settings → System → Notifications)
- Ensure "Get notifications from apps and other senders" is enabled
- Verify Focus Assist is not blocking notifications

Icon Not Appearing in Tray:
- Check if the script is running: `Get-Process powershell`
- Look for hidden tray icons (click the up arrow in the system tray)

 Customization

 Adjusting Thresholds

Modify threshold values based on your system requirements:

- CPU: Lower values (e.g., 70) for earlier warnings
- Memory: Increase for systems with lots of RAM (e.g., 20%)
- Disk: Adjust based on drive size (larger drives may use percentage + GB checks)

 Modifying Check Intervals

TrayMonitor: Change `$CheckInterval` (in milliseconds)
```powershell
$CheckInterval = 30000   Check every 30 seconds
```

BackgroundMonitor: Adjust the scheduled task interval

 Adding Custom Logic

Both scripts can be extended:
- Add network monitoring
- Monitor specific processes
- Check service status
- Custom notification methods (Slack, Teams, etc.)

 Security Considerations

1. Credentials: If using authenticated SMTP, use `PSCredential` objects instead of plain-text passwords
2. Execution Policy: Review your organization's PowerShell execution policies
3. Event Log: Ensure appropriate log retention and monitoring policies
4. Scheduled Tasks: Use service accounts with minimal required privileges

 Performance Impact

- BackgroundMonitor: Minimal impact (runs briefly, then exits)
- TrayMonitor: ~5-10MB memory usage, negligible CPU when idle

 Version History

 Version 1.1 (2026-01-02)
- Fixed unapproved verb warning (renamed Run-Check to Invoke-Check)
- Enhanced error handling
- Improved email configuration validation
- Added comprehensive documentation

 Version 1.0
- Initial release
- Basic CPU, RAM, and disk monitoring
- Email and event log integration
- System tray notification support

 License

This project is provided as-is for educational and operational use.

 Support

For issues or questions:
1. Check the Troubleshooting section
2. Review Windows Event Viewer for detailed error messages
3. Enable verbose logging by adding `-Verbose` parameter support

 Contributing

Suggestions for improvements:
- Add support for monitoring multiple remote computers
- Implement SMS notifications
- Create a web dashboard
- Add historical data logging and trending
- Integration with monitoring platforms (PRTG, Nagios, etc.)

---

Author: System Administrator
Last Updated: January 2, 2026
