# PowerShell script to set up automatic server startup
$serverPath = "c:\Users\Hazem\clean_flutter\server"
$batchFile = "$serverPath\start_server_silent.bat"

# Create a scheduled task to run the server at startup
$action = New-ScheduledTaskAction -Execute $batchFile
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

Register-ScheduledTask -TaskName "E2EE Server Auto Start" -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Automatically starts the E2EE server at Windows startup"

Write-Host "Task scheduled successfully! Server will start automatically on Windows startup."
Write-Host "To remove this task later, run: Unregister-ScheduledTask -TaskName 'E2EE Server Auto Start'"
