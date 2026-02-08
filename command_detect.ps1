$token = "..."
$chatid = "..."

try {
    
    $Log = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -FilterHashtable @{ID=1} -MaxEvents 1 -ErrorAction SilentlyContinue
    
    if ($Log) {
        $XML = [xml]$Log.ToXml()
        $Data = $XML.Event.EventData.Data

        $User        = ($Data | Where-Object {$_.Name -eq "User"})."#text"
        $CommandLine = ($Data | Where-Object {$_.Name -eq "CommandLine"})."#text"
        $Parent      = ($Data | Where-Object {$_.Name -eq "ParentImage"})."#text"
        $LogonId     = ($Data | Where-Object {$_.Name -eq "LogonId"})."#text"
        $Time        = $Log.TimeCreated

       
        if ($CommandLine -like "*conhost.exe*" -or $CommandLine -like "*l.ps1*") { exit }

        
        $HackerTools = @("whoami", "net user", "ipconfig", "systeminfo", "taskkill", "net1", "quser", "netstat", "reg query")
        $IsHacker = $false
        foreach ($tool in $HackerTools) { if ($CommandLine -like "*$tool*") { $IsHacker = $true; break } }

       
        if ($Parent -like "*cmd.exe*" -or $Parent -like "*powershell.exe*" -or $IsHacker) {
            
            
            $LocalIP = (Get-NetRoute | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' } | 
                        ForEach-Object { Get-NetIPAddress -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4 } | 
                        Select-Object -ExpandProperty IPAddress -First 1)

            
            try {
                $LogonEvent = Get-WinEvent -FilterHashTable @{LogName='Security'; ID=4624} -ErrorAction SilentlyContinue | 
                              Where-Object { $_.Properties[7].Value -eq $LogonId } | Select-Object -First 1
                if ($LogonEvent) {
                    $RemoteIP = $LogonEvent.Properties[18].Value
                    if ($RemoteIP -eq "127.0.0.1" -or $RemoteIP -eq "::1" -or $RemoteIP -eq "-") {
                        $IP_Status = "INTERNAL ATTACK / LOCAL ACCESS"
                        $FinalIP = "localhost"
                    } else {
                        $IP_Status = "EXTERNAL ACCESS DETECTED"
                        $FinalIP = $RemoteIP
                    }
                } else { $FinalIP = "N/A"; $IP_Status = "Session Not Found" }
            } catch { $FinalIP = "Error"; $IP_Status = "Error" }

            
            $Pesan = "--- COMMAND EXECUTION DETECTED ---`n" +
                     "Waktu      : $Time`n" +
                     "User       : $User`n" +
                     "Status     : $IP_Status`n" +
                     "IP Pelaku  : $FinalIP`n" +
                     "IP Host PC : $LocalIP`n" +
                     "Perintah   : $CommandLine`n" +
                     "Parent     : $Parent`n" +
                     "----------------------------------"

            Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/sendMessage" -Method Post -Body @{chat_id=$chatid; text=$Pesan}
        }
    }
} catch { exit }
