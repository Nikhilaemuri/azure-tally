[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Ssl3
[Net.ServicePointManager]::SecurityProtocol = "Tls, Tls11, Tls12, Ssl3"
Invoke-WebRequest -Uri "https://tallymirror.tallysolutions.com/download_centre/Rel_2.1/TP/Full/setup.exe" -OutFile "C:\Users\adminuser\Downloads\setup.exe"
New-Item -Path 'C:\Users\adminuser\Downloads\test_folder' -ItemType Directory