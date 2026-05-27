# Kripto Uygulaması Yükleme Betiği
# Bu betik Python'ın kurulu olup olmadığını kontrol eder, yoksa kurar, bağımlılıkları yükler ve kayıt defteri entegrasyonlarını yapar.

$ErrorActionPreference = "Stop"

Write-Host "=== Kripto Kurulum Sihirbazı ===" -ForegroundColor Cyan

# 1. Python Kontrolü ve Kurulumu
$pythonInstalled = $false
try {
    $version = & python --version 2>&1
    if ($lastExitCode -eq 0) {
        $pythonInstalled = $true
        Write-Host "Python zaten kurulu: $version" -ForegroundColor Green
    }
} catch {
    # Python kurulu değil veya PATH üzerinde değil
}

if (-not $pythonInstalled) {
    Write-Host "Python bulunamadı. Python 3.12.3 indiriliyor..." -ForegroundColor Yellow
    $url = "https://www.python.org/ftp/python/3.12.3/python-3.12.3-amd64.exe"
    $installerPath = "$env:TEMP\python-installer.exe"
    
    # İlerleme çubuğunu gizle (indirmeyi hızlandırır)
    $progressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $url -OutFile $installerPath
    $progressPreference = 'Continue'
    
    Write-Host "Python kuruluyor (Sessiz Kurulum)... Bu işlem bir dakika kadar sürebilir." -ForegroundColor Yellow
    # Sessiz kurulum parametreleri: quiet (sessiz), PrependPath (PATH'e ekle)
    $process = Start-Process -FilePath $installerPath -ArgumentList "/quiet PrependPath=1 Include_test=0 InstallAllUsers=0" -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "Python başarıyla kuruldu." -ForegroundColor Green
    } else {
        Write-Warning "Python kurulumu hata koduyla bitti: $($process.ExitCode). Lütfen manuel kurmayı deneyin."
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
    Write-Host "Kütüphaneler hazır." -ForegroundColor Green
} catch {
    Write-Warning "Python paketleri yüklenirken hata oluştu: $_"
}

# 3. Dosyaların Kopyalanması
$installDir = "$env:LocalAppData\Kripto"
Write-Host "Dosyalar hedefe kopyalanıyor: $installDir" -ForegroundColor Cyan

if (-not (Test-Path $installDir)) {
    New-Item -Path $installDir -ItemType Directory | Out-Null
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Copy-Item -Path "$scriptDir\kripto.py" -Destination $installDir -Force
Copy-Item -Path "$scriptDir\kripto.ico" -Destination $installDir -Force

Write-Host "Dosya kopyalama tamamlandı." -ForegroundColor Green

# 4. Kayıt Defteri (Registry) Entegrasyonu
Write-Host "Kayıt defteri entegrasyonu yapılıyor..." -ForegroundColor Cyan

# Yardımcı fonksiyonlar
function Set-RegKeyDefault {
    param ($Path, $Value)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-Item -Path $Path -Value $Value | Out-Null
}

function Set-RegValue {
    param ($Path, $Name, $Value)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force | Out-Null
}

try {
    # Eski genel 'Sifre Coz' seçeneğini temizliyoruz
    Remove-Item -Path "HKCU:\Software\Classes\*\shell\KriptoSifreCoz" -Recurse -ErrorAction SilentlyContinue

    # Pythonw.exe ve dosya yolları
    $pythonwPath = "pythonw.exe"
    $pyFile = "$installDir\kripto.py"
    $icoFile = "$installDir\kripto.ico"

    # --- Şifrele Menüsü ---
    $sifreleKey = "HKCU:\Software\Classes\*\shell\KriptoSifrele"
    Set-RegKeyDefault -Path $sifreleKey -Value "Kripto - Şifrele"
    Set-RegValue -Path $sifreleKey -Name "Icon" -Value "shell32.dll,47"
    Set-RegValue -Path $sifreleKey -Name "AppliesTo" -Value "NOT System.FileExtension:=.enc"

    $sifreleCmdKey = "$sifreleKey\command"
    Set-RegKeyDefault -Path $sifreleCmdKey -Value "$pythonwPath `"$pyFile`" -l `"%1`""

    # --- .enc Uzantısı İlişkilendirmesi ---
    # Önceki kullanıcı tercihlerini temizleyelim ki bizim tanımımız öncelikli olsun
    Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.enc\UserChoice" -Force -ErrorAction SilentlyContinue

    $encKey = "HKCU:\Software\Classes\.enc"
    Set-RegKeyDefault -Path $encKey -Value "EncryptedFile"

    # Varsayılan Simge
    $iconKey = "HKCU:\Software\Classes\EncryptedFile\DefaultIcon"
    Set-RegKeyDefault -Path $iconKey -Value $icoFile

    # --- Şifre Çöz Menüsü ---
    $cozKey = "HKCU:\Software\Classes\EncryptedFile\shell\KriptoSifreCoz"
    Set-RegKeyDefault -Path $cozKey -Value "Kripto - Şifre Çöz"
    Set-RegValue -Path $cozKey -Name "Icon" -Value "shell32.dll,47"
    Set-RegValue -Path $cozKey -Name "NeverDefault" -Value ""

    $cozCmdKey = "$cozKey\command"
    Set-RegKeyDefault -Path $cozCmdKey -Value "$pythonwPath `"$pyFile`" -u `"%1`""

    # --- Çift Tıklama (Aç ve Düzenle) Eylemi ---
    $openKey = "HKCU:\Software\Classes\EncryptedFile\shell\open"
    Set-RegKeyDefault -Path $openKey -Value "Kripto - Aç ve Düzenle"
    Set-RegValue -Path $openKey -Name "Icon" -Value "shell32.dll,47"

    $openCmdKey = "$openKey\command"
    Set-RegKeyDefault -Path $openCmdKey -Value "$pythonwPath `"$pyFile`" -o `"%1`""

    Write-Host "Kayıt defteri entegrasyonu başarıyla tamamlandı!" -ForegroundColor Green
} catch {
    Write-Warning "Kayıt defteri güncellenirken bir hata oluştu: $_"
}

Write-Host "`nKurulum başarıyla tamamlandı! Artık dosyalarınıza sağ tıklayarak şifreleme/şifre çözme işlemlerini yapabilirsiniz." -ForegroundColor Green
Write-Host "Çıkmak için bir tuşa basın..."
[void][System.Console]::ReadKey()
