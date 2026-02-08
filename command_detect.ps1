
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$token = ".."
$chatid = ".."


$lastProcessedId = 0

while($true) {
    try {
       
        $Log = Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-Sysmon/Operational"; ID=1} -MaxEvents 1 -ErrorAction SilentlyContinue
        
        if ($Log -and $Log.RecordId -ne $lastProcessedId) {
            $lastProcessedId = $Log.RecordId
            
            $XML = [xml]$Log.ToXml()
            $Data = $XML.Event.EventData.Data

            $User        = ($Data | Where-Object {$_.Name -eq "User"})."#text"
            $CommandLine = ($Data | Where-Object {$_.Name -eq "CommandLine"})."#text"
            $Parent      = ($Data | Where-Object {$_.Name -eq "ParentImage"})."#text"
            $Time        = $Log.TimeCreated

          
            if ($CommandLine -like "*monitor_perintah.ps1*") { continue }

            
            if ($Parent -like "*cmd.exe*" -or $Parent -like "*powershell.exe*") {
                
               
                $LocalIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object -ExpandProperty IPAddress -First 1)

         
                $Pesan = "--- ALERT: COMMAND DETECTED ---`n" +
                         "Waktu      : $Time`n" +
                         "User       : $User`n" +
                         "IP Host PC : $LocalIP`n" +
                         "Perintah   : $CommandLine`n" +
                         "Parent     : $Parent`n" +
                         "-------------------------------"

                
                Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/sendMessage" -Method Post -Body @{chat_id=$chatid; text=$Pesan}
            }
        }
    } catch { 
       
    }
    
   
    Start-Sleep -Seconds 1
}
