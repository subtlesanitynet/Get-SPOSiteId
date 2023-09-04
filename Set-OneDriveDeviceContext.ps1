[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Try {
    $reg = Get-Item -Path Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\OneDrive
    if (!$reg) {
        $file = "C:\OneDriveSetup.exe"
        $url = "https://go.microsoft.com/fwlink/?linkid=844652"
        Invoke-WebRequest -Uri $url -Outfile $file -UseBasicParsing
        if (Test-Path -Path $file -PathType Leaf) {
            Start-Process $file -ArgumentList "/allusers"
        }
    } else {
        "OneDrive already set to device context!"
    }
} Catch {
    $_ | Select *
}