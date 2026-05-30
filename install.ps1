# Kripto Uygulamasi Yukleme Betigi
# Bu betik Python'in kurulu olup olmadigini kontrol eder, yoksa kurar, bagliliklari yukler ve kayit defteri entegrasyonlarini yapar.

$ErrorActionPreference = "Stop"

Write-Host "=== Kripto Kurulum Sihirbazi - Eren Gunduzvar ===" -ForegroundColor Cyan

# 1. Python Kontrolu ve Kurulumu
$pythonInstalled = $false
try {
    $version = & python --version 2>&1
    if ($lastExitCode -eq 0) {
        $pythonInstalled = $true
        Write-Host "Python zaten kurulu: $version" -ForegroundColor Green
    }
}
catch {
    # Python kurulu degil veya PATH uzerinde degil
}

if (-not $pythonInstalled) {
    Write-Host "Python bulunamadi. Python 3.12.3 indiriliyor..." -ForegroundColor Yellow
    $url = "https://www.python.org/ftp/python/3.12.3/python-3.12.3-amd64.exe"
    $installerPath = "$env:TEMP\python-installer.exe"
    
    # Ilerleme cubugunu gizle (indirmeyi hizlandirir)
    $progressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $url -OutFile $installerPath
    $progressPreference = 'Continue'
    
    Write-Host "Python kuruluyor (Sessiz Kurulum)... Bu islem bir dakika kadar surebilir." -ForegroundColor Yellow
    # Sessiz kurulum parametreleri: quiet (sessiz), PrependPath (PATH'e ekle)
    $process = Start-Process -FilePath $installerPath -ArgumentList "/quiet PrependPath=1 Include_test=0 InstallAllUsers=0" -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "Python basariyla kuruldu." -ForegroundColor Green
    }
    else {
        Write-Warning "Python kurulumu hata koduyla bitti: $($process.ExitCode). Lutfen manuel kurmayi deneyin."
    }
    
    # Ortam değişkenlerini güncel session için yenileyelim
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
}

# 2. Bağımlılıkların Kurulumu
Write-Host "Gerekli Python paketleri kontrol ediliyor..." -ForegroundColor Cyan
try {
    # pip güncelleme
    & python -m pip install --upgrade pip --quiet
    # cryptography paketi
    & python -m pip install cryptography --quiet
    Write-Host "Kutuphaneler hazir." -ForegroundColor Green
}
catch {
    Write-Warning "Python paketleri yuklenirken hata olustu: $_"
}

# 3. Dosyaların Kopyalanması
$installDir = "$env:LocalAppData\Kripto"
Write-Host "Dosyalar hedefe kopyalaniyor: $installDir" -ForegroundColor Cyan

if (-not (Test-Path $installDir)) {
    New-Item -Path $installDir -ItemType Directory | Out-Null
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Copy-Item -Path "$scriptDir\kripto.py" -Destination $installDir -Force
Copy-Item -Path "$scriptDir\kripto.ico" -Destination $installDir -Force
Copy-Item -Path "$scriptDir\uninstall.exe" -Destination $installDir -Force
Copy-Item -Path "$scriptDir\uninstall.ps1" -Destination $installDir -Force

Write-Host "Dosya kopyalama tamamlandi." -ForegroundColor Green

# 4. Kayit Defteri (Registry) Entegrasyonu
Write-Host "Kayit defteri entegrasyonu yapiliyor..." -ForegroundColor Cyan

# Yardımcı fonksiyonlar (.NET Registry API kullanarak donmaları ve wildcard sorunlarını önler)
function Set-RegKeyDefault {
    param ($Path, $Value)
    $subKeyPath = $Path.Replace("HKCU:\", "")
    $regKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($subKeyPath)
    if ($regKey -ne $null) {
        $regKey.SetValue("", $Value)
        $regKey.Close()
    }
}

function Set-RegValue {
    param ($Path, $Name, $Value)
    $subKeyPath = $Path.Replace("HKCU:\", "")
    $regKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($subKeyPath)
    if ($regKey -ne $null) {
        $regKey.SetValue($Name, $Value)
        $regKey.Close()
    }
}

try {
    # Eski genel kayıtları temizliyoruz
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree("Software\Classes\*\shell\KriptoSifrele", $false)
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree("Software\Classes\*\shell\KriptoSifreCoz", $false)
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree("Software\Classes\EncryptedFile\shell\KriptoSifreCoz", $false)
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree("Software\Classes\*\shell\KriptoMenu", $false)

    # Pythonw.exe mutlak yolunu bul (Windows Store hatasını önlemek için)
    $pythonwPath = "pythonw.exe"
    $regPaths = @(
        "HKCU:\SOFTWARE\Python\PythonCore\*\InstallPath",
        "HKLM:\SOFTWARE\Python\PythonCore\*\InstallPath",
        "HKLM:\SOFTWARE\Wow6432Node\Python\PythonCore\*\InstallPath"
    )
    
    foreach ($regPath in $regPaths) {
        $paths = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
        if ($paths) {
            foreach ($p in $paths) {
                if ($p.WindowedExecutablePath -and (Test-Path $p.WindowedExecutablePath)) {
                    $pythonwPath = $p.WindowedExecutablePath
                    break
                }
                elseif ($p.ExecutablePath -and (Test-Path $p.ExecutablePath)) {
                    $dir = Split-Path $p.ExecutablePath
                    $wPath = Join-Path $dir "pythonw.exe"
                    if (Test-Path $wPath) {
                        $pythonwPath = $wPath
                        break
                    }
                }
            }
        }
        if ($pythonwPath -ne "pythonw.exe") { break }
    }

    # Kayıt defterinde bulamazsa komut satırından bul, ancak WindowsApps (Mağaza) sahtesini yoksay
    if ($pythonwPath -eq "pythonw.exe") {
        $pathsFromPath = Get-Command pythonw.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
        if ($pathsFromPath) {
            foreach ($p in $pathsFromPath) {
                if ($p -notlike "*WindowsApps*") {
                    $pythonwPath = $p
                    break
                }
            }
        }
    }
    $pyFile = "$installDir\kripto.py"
    $icoFile = "$installDir\kripto.ico"

    # --- Ana Kripto Menüsü (Cascading Menu) ---
    $menuKey = "HKCU:\Software\Classes\*\shell\KriptoMenu"
    Set-RegValue -Path $menuKey -Name "MUIVerb" -Value "Kripto"
    Set-RegValue -Path $menuKey -Name "Icon" -Value "shell32.dll,47"
    Set-RegValue -Path $menuKey -Name "SubCommands" -Value ""

    # --- Şifrele Alt Menüsü ---
    $sifreleKey = "$menuKey\shell\KriptoSifrele"
    Set-RegKeyDefault -Path $sifreleKey -Value "Sifrele"
    Set-RegValue -Path $sifreleKey -Name "Icon" -Value "shell32.dll,47"
    Set-RegValue -Path $sifreleKey -Name "AppliesTo" -Value "NOT System.FileExtension:=.enc"

    $sifreleCmdKey = "$sifreleKey\command"
    Set-RegKeyDefault -Path $sifreleCmdKey -Value "`"$pythonwPath`" `"$pyFile`" -l `"%1`""

    # --- Şifre Çöz Alt Menüsü ---
    $cozKey = "$menuKey\shell\KriptoSifreCoz"
    Set-RegKeyDefault -Path $cozKey -Value "Sifre Coz"
    Set-RegValue -Path $cozKey -Name "Icon" -Value "shell32.dll,47"
    Set-RegValue -Path $cozKey -Name "AppliesTo" -Value "System.FileExtension:=.enc"

    $cozCmdKey = "$cozKey\command"
    Set-RegKeyDefault -Path $cozCmdKey -Value "`"$pythonwPath`" `"$pyFile`" -u `"%1`""

    # --- Aç ve Düzenle Alt Menüsü ---
    $openKey = "$menuKey\shell\KriptoAc"
    Set-RegKeyDefault -Path $openKey -Value "Ac ve Duzenle"
    Set-RegValue -Path $openKey -Name "Icon" -Value "shell32.dll,47"
    Set-RegValue -Path $openKey -Name "AppliesTo" -Value "System.FileExtension:=.enc"

    $openCmdKey = "$openKey\command"
    Set-RegKeyDefault -Path $openCmdKey -Value "`"$pythonwPath`" `"$pyFile`" -o `"%1`""

    # --- Kripto'yu Kaldır Alt Menüsü ---
    $kaldirKey = "$menuKey\shell\KriptoKaldir"
    Set-RegKeyDefault -Path $kaldirKey -Value "Kripto'yu Kaldir"
    Set-RegValue -Path $kaldirKey -Name "Icon" -Value "shell32.dll,131"
    
    $uninstallCmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command `"`$w = New-Object -ComObject Wscript.Shell; if (`$w.Popup('Kripto uygulamasini kaldirmak istediginize emin misiniz?', 0, 'Kripto Kaldirma', 4+32) -eq 6) { Start-Process -FilePath '$installDir\uninstall.exe' -Verb RunAs }`""
    Set-RegKeyDefault -Path "$kaldirKey\command" -Value $uninstallCmd

    # --- .enc Uzantisi Iliskilendirmesi ve Çift Tıklama ---
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree("Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.enc\UserChoice", $false)

    $encKey = "HKCU:\Software\Classes\.enc"
    Set-RegKeyDefault -Path $encKey -Value "EncryptedFile"

    # Varsayılan Simge (.enc dosyaları için)
    $iconKey = "HKCU:\Software\Classes\EncryptedFile\DefaultIcon"
    Set-RegKeyDefault -Path $iconKey -Value $icoFile

    # Çift Tıklama (Aç ve Düzenle)
    $doubleClickKey = "HKCU:\Software\Classes\EncryptedFile\shell\open\command"
    Set-RegKeyDefault -Path $doubleClickKey -Value "`"$pythonwPath`" `"$pyFile`" -o `"%1`""

    Write-Host "Kayit defteri entegrasyonu basariyla tamamlandi!" -ForegroundColor Green
}
catch {
    Write-Warning "Kayit defteri guncellenirken bir hata olustu: $_"
}

Write-Host "`nKurulum basariyla tamamlandi! Artik dosyalariniza sag tiklayarak sifreleme/sifre cozme islemlerini yapabilirsiniz." -ForegroundColor Green
Write-Host "Cikmak icin bir tusa basin..."
[void][System.Console]::ReadKey()
