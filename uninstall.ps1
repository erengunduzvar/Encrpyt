# Kripto Uygulaması Kaldırma Betiği
# Bu betik kayıt defteri entegrasyonlarını temizler ve uygulama klasörünü kaldırır. Python'a dokunmaz.

$ErrorActionPreference = "Continue"

Write-Host "=== Kripto Kaldırma Sihirbazı ===" -ForegroundColor Yellow

# 1. Kayıt Defteri (Registry) Temizliği
Write-Host "Kayıt defteri entegrasyonları kaldırılıyor..." -ForegroundColor Cyan

try {
    # Şifrele menüsünü kaldır
    if (Test-Path "HKCU:\Software\Classes\*\shell\KriptoSifrele") {
        Remove-Item -Path "HKCU:\Software\Classes\*\shell\KriptoSifrele" -Recurse -Force
    }
    
    # Eski Şifre Çöz menüsü kalıntısı varsa kaldır
    if (Test-Path "HKCU:\Software\Classes\*\shell\KriptoSifreCoz") {
        Remove-Item -Path "HKCU:\Software\Classes\*\shell\KriptoSifreCoz" -Recurse -Force
    }

    # .enc Uzantı ilişkilendirmelerini kaldır
    if (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.enc\UserChoice") {
        Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.enc\UserChoice" -Force
    }
    
    if (Test-Path "HKCU:\Software\Classes\.enc") {
        Remove-Item -Path "HKCU:\Software\Classes\.enc" -Recurse -Force
    }
    
    if (Test-Path "HKCU:\Software\Classes\EncryptedFile") {
        Remove-Item -Path "HKCU:\Software\Classes\EncryptedFile" -Recurse -Force
    }

    Write-Host "Kayıt defteri temizliği tamamlandı." -ForegroundColor Green
} catch {
    Write-Warning "Kayıt defteri temizlenirken bazı hatalar oluştu: $_"
}

# 2. Dosyaların Silinmesi
$installDir = "$env:LocalAppData\Kripto"
if (Test-Path $installDir) {
    Write-Host "Uygulama dosyaları siliniyor: $installDir" -ForegroundColor Cyan
    try {
        Remove-Item -Path $installDir -Recurse -Force
        Write-Host "Uygulama klasörü başarıyla silindi." -ForegroundColor Green
    } catch {
        Write-Warning "Uygulama klasörü silinirken hata oluştu: $_"
    }
} else {
    Write-Host "Uygulama klasörü zaten bulunamadı." -ForegroundColor Green
}

Write-Host "`nKaldırma işlemi başarıyla tamamlandı!" -ForegroundColor Green
Write-Host "Çıkmak için bir tuşa basın..."
[void][System.Console]::ReadKey()
