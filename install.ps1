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
    # Eski genel 'Sifre Coz' secenegini temizliyoruz
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree("Software\Classes\*\shell\KriptoSifreCoz", $false)

    # Pythonw.exe ve dosya yolları
    $pythonwPath = "pythonw.exe"
    $pyFile = "$installDir\kripto.py"
    $icoFile = "$installDir\kripto.ico"

    # --- Sifrele Menusu ---
    $sifreleKey = "HKCU:\Software\Classes\*\shell\KriptoSifrele"
    Set-RegKeyDefault -Path $sifreleKey -Value "Kripto - Sifrele"
    Set-RegValue -Path $sifreleKey -Name "Icon" -Value "shell32.dll,47"
    Set-RegValue -Path $sifreleKey -Name "AppliesTo" -Value "NOT System.FileExtension:=.enc"

    $sifreleCmdKey = "$sifreleKey\command"
    Set-RegKeyDefault -Path $sifreleCmdKey -Value "$pythonwPath `"$pyFile`" -l `"%1`""

    # --- .enc Uzantisi Iliskilendirmesi ---
    # Onceki kullanici tercihlerini temizleyelim ki bizim tanimimiz oncelikli olsun
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree("Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.enc\UserChoice", $false)

    $encKey = "HKCU:\Software\Classes\.enc"
    Set-RegKeyDefault -Path $encKey -Value "EncryptedFile"

    # Varsayılan Simge
    $iconKey = "HKCU:\Software\Classes\EncryptedFile\DefaultIcon"
    Set-RegKeyDefault -Path $iconKey -Value $icoFile

    # --- Sifre Coz Menusu ---
    $cozKey = "HKCU:\Software\Classes\EncryptedFile\shell\KriptoSifreCoz"
    Set-RegKeyDefault -Path $cozKey -Value "Kripto - Sifre Coz"
    Set-RegValue -Path $cozKey -Name "Icon" -Value "shell32.dll,47"
    Set-RegValue -Path $cozKey -Name "NeverDefault" -Value ""

    $cozCmdKey = "$cozKey\command"
    Set-RegKeyDefault -Path $cozCmdKey -Value "$pythonwPath `"$pyFile`" -u `"%1`""

    # --- Cift Tiklama (Ac ve Duzenle) Eylemi ---
    $openKey = "HKCU:\Software\Classes\EncryptedFile\shell\open"
    Set-RegKeyDefault -Path $openKey -Value "Kripto - Ac ve Duzenle"
    Set-RegValue -Path $openKey -Name "Icon" -Value "shell32.dll,47"

    $openCmdKey = "$openKey\command"
    Set-RegKeyDefault -Path $openCmdKey -Value "$pythonwPath `"$pyFile`" -o `"%1`""

    Write-Host "Kayit defteri entegrasyonu basariyla tamamlandi!" -ForegroundColor Green
}
catch {
    Write-Warning "Kayit defteri guncellenirken bir hata olustu: $_"
}

Write-Host "`nKurulum basariyla tamamlandi! Artik dosyalariniza sag tiklayarak sifreleme/sifre cozme islemlerini yapabilirsiniz." -ForegroundColor Green
Write-Host "Cikmak icin bir tusa basin..."
[void][System.Console]::ReadKey()
