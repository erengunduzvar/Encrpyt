# Kripto Uygulamasi Kaldirma Betigi
# Bu betik kayit defteri entegrasyonlarini temizler ve uygulama klasorunu kaldirir. Python'a dokunmaz.

$currentScript = $MyInvocation.MyCommand.Definition
$installDir = "$env:LocalAppData\Kripto"

# Kilitlenmeyi onlemek icin betik eger hedef klasorun icindeyse kendini TEMP'e kopyalayip oradan calistirir
if ($currentScript -like "$installDir\*") {
    $tempScript = "$env:TEMP\uninstall.ps1"
    Copy-Item -Path $currentScript -Destination $tempScript -Force
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempScript`""
    Exit
}

# Kilidin tamamen kalkmasi icin kisa bir sure bekleyelim
if ($currentScript -like "$env:TEMP\*") {
    Start-Sleep -Seconds 1
}

Write-Host "=== Kripto Kaldirma Sihirbazi - Eren Gunduzvar ===" -ForegroundColor Yellow

# 1. Kayit Defteri (Registry) Temizligi
Write-Host "Kayit defteri entegrasyonlari kaldiriliyor..." -ForegroundColor Cyan

try {
    # Kayit defteri temizligi (.NET API ile guvenli ve hizli)
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree("Software\Classes\*\shell\KriptoMenu", $false)
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree("Software\Classes\*\shell\KriptoSifrele", $false)
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree("Software\Classes\*\shell\KriptoSifreCoz", $false)
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree("Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.enc\UserChoice", $false)
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree("Software\Classes\.enc", $false)
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree("Software\Classes\EncryptedFile", $false)

    Write-Host "Kayit defteri temizligi tamamlandi." -ForegroundColor Green
}
catch {
    Write-Warning "Kayit defteri temizlenirken bazi hatalar olustu: $_"
}

# 2. Dosyalarin Silinmesi
$installDir = "$env:LocalAppData\Kripto"
if (Test-Path $installDir) {
    Write-Host "Uygulama dosyalari siliniyor: $installDir" -ForegroundColor Cyan
    try {
        Remove-Item -Path $installDir -Recurse -Force
        Write-Host "Uygulama klasoru basariyla silindi." -ForegroundColor Green
    }
    catch {
        Write-Warning "Uygulama klasoru silinirken hata olustu: $_"
    }
}
else {
    Write-Host "Uygulama klasoru zaten bulunamadi." -ForegroundColor Green
}

Write-Host "`nKaldirma islemi basariyla tamamlandi!" -ForegroundColor Green
Write-Host "Cikmak icin bir tusa basin..."
[void][System.Console]::ReadKey()
