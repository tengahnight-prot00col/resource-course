$token = "..."
$chatid = "..."

try {
    $Log = Get-WinEvent -FilterHashTable @{LogName='Security'; ID=4663} -MaxEvents 20 -ErrorAction SilentlyContinue | 
           Where-Object { $_.Properties[6].Value -like "C:\Rahasia\*" } | Select-Object -First 1
} catch { $Log = $null }

if ($Log) {
    $SubjectUser = $Log.Properties[1].Value
    $LogonId     = $Log.Properties[3].Value
    $FilePath    = $Log.Properties[6].Value
    $ProcessName = $Log.Properties[10].Value 
    $Time        = $Log.TimeCreated

    $LocalIP = (Get-NetRoute | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' } | 
                ForEach-Object { Get-NetIPAddress -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4 } | 
                Select-Object -ExpandProperty IPAddress -First 1)

    try {
        $LogonEvent = Get-WinEvent -FilterHashTable @{LogName='Security'; ID=4624} -ErrorAction SilentlyContinue | 
                      Where-Object { $_.Properties[7].Value -eq $LogonId } | Select-Object -First 1
        if ($LogonEvent) {
            $RemoteIP = $LogonEvent.Properties[18].Value
            $LogonType = $LogonEvent.Properties[8].Value
            if ($RemoteIP -eq "127.0.0.1" -or $RemoteIP -eq "::1" -or $RemoteIP -eq "-") {
                $IP_Status = "WARNING: INTERNAL ATTACK / LOCAL ACCESS"
                $FinalIP = "localhost"
            } else {
                $IP_Status = "EXTERNAL ACCESS DETECTED"
                $FinalIP = $RemoteIP
            }
            $TypeDesc = switch($LogonType) { 2 {"Local-Interactive"}; 3 {"Network-SMB"}; 10 {"RDP"}; 11 {"Cached"}; default {"Type-$LogonType"} }
        } else { $FinalIP = "N/A"; $IP_Status = "No Session"; $TypeDesc = "N/A" }
    } catch { $FinalIP = "Error" }

    $Pesan = "--- SECURITY ALERT: FILE ACCESS ---`n" +
             "Waktu      : $Time `n" +
             "User       : $SubjectUser `n" +
             "Status     : $IP_Status `n" +
             "IP Pelaku  : $FinalIP `n" +
             "IP Host PC : $LocalIP `n" +
             "Logon Type : $TypeDesc `n" +
             "File       : $FilePath `n" +
             "Proses     : $ProcessName `n" +
             "------------------------------------"
    Invoke-RestMethod -Uri "https://api.telegram.org/bot$token/sendMessage" -Method Post -Body @{chat_id=$chatid; text=$Pesan}
}
