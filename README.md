# 🔒 Kripto - Windows Context Menu Dosya Şifreleme Aracı

Kripto, Windows işletim sistemi üzerinde dosyalarınızı en yüksek güvenlik standartlarıyla şifrelemenizi, şifrelerini çözmenizi ve şifreli dosyaları doğrudan açıp düzenlemenizi sağlayan, Windows Sağ Tık (Context Menu) entegrasyonlu modern ve pratik bir güvenlik aracıdır.

---

## ✨ Özellikler

*   **Güçlü Şifreleme:** Askeri düzeyde güvenlik için **AES-256-GCM** (Galois/Counter Mode) şifreleme algoritması kullanılır.
*   **Güvenli Anahtar Türetimi:** Parolanız, tahmin edilmesi veya kırılması neredeyse imkansız hale getirilmesi için **PBKDF2HMAC** (SHA256, 600.000 iterasyon) ile tuzlanarak (salt) anahtara dönüştürülür.
*   **Windows Sağ Tık Entegrasyonu:** Dosyalara sağ tıklayarak açılan menüden doğrudan şifreleme, şifre çözme işlemlerini yapabilirsiniz.
*   **Aç ve Düzenle (Çift Tıklama Desteği):** `.enc` uzantılı şifreli dosyalara çift tıkladığınızda veya sağ tıklayıp "Aç ve Düzenle" dediğinizde:
    1. Geçici olarak şifre çözülür ve varsayılan uygulamasıyla açılır.
    2. Arka planda açılan küçük kontrol penceresiyle düzenlemelerinizi takip eder.
    3. İşiniz bittiğinde tek tuşla dosyayı **tekrar güvenli bir şekilde şifreler** ve geçici şifresiz dosyayı bilgisayarınızdan güvenle siler.
*   **Otomatik Kurulum & Kaldırma:** Kolay kurulum (`setup.exe`) ve kaldırma (`uninstall.exe`) araçları sayesinde Python kurulumundan kütüphanelere, kayıt defteri (Registry) ayarlarından dosya ikonlarına kadar her şey otomatik kurulur.

---

## 🛠️ Nasıl Kurulur?

Projeyi bilgisayarınıza kurmak son derece basittir. Kurulum sihirbazı sisteminizde Python yoksa otomatik olarak indirip kuracaktır.

1.  Proje klasörünü bilgisayarınıza indirin.
2.  **`setup.exe`** dosyasını çift tıklayarak çalıştırın.
3.  Ekrandaki yönergeleri takip edin. Kurulum tamamlandığında Windows Gezgini'ne sağ tık menüsü ve `.enc` dosya ilişkisi otomatik olarak entegre edilmiş olacaktır.

---

## 🗑️ Nasıl Kaldırılır?

Uygulamayı sisteminizden tamamen temizlemek için iki yöntemden birini kullanabilirsiniz:

*   **1. Yöntem:** Herhangi bir dosyaya sağ tıklayıp **Kripto** menüsü altındaki **"Kripto'yu Kaldır"** seçeneğine tıklayın.
*   **2. Yöntem:** Proje klasöründeki **`uninstall.exe`** dosyasını çalıştırın.

Bu işlem yaptığınız tüm Windows entegrasyonlarını ve kayıt defteri kayıtlarını otomatik olarak temizleyecektir.

---

## 💻 Manuel Kullanım ve Komut Satırı (CLI)

Kripto'yu komut satırı üzerinden parametreler vererek de kullanabilirsiniz:

### 1. Dosya Şifreleme (Lock)
```bash
python kripto.py -l <dosya_adi> [parolaniz]
```
*Eğer parolanızı komut satırında belirtmezseniz, şifre girmek için güvenli bir arayüz (GUI) penceresi açılacaktır.*

### 2. Şifre Çözme (Unlock)
```bash
python kripto.py -u <sifreli_dosya_adi> [parolaniz]
```

### 3. Açma ve Düzenleme (Open & Edit)
```bash
python kripto.py -o <sifreli_dosya_adi> [parolaniz]
```

---

## 📁 Proje Yapısı

```text
Encrpyt/
│
├── kripto.py               # Ana uygulama mantığı ve GUI kodu (Python)
├── kripto.ico              # Şifreli (.enc) dosyalar için özel kilit ikonu
├── install.ps1             # Windows otomatik kurulum PowerShell betiği
├── uninstall.ps1           # Windows otomatik kaldırma PowerShell betiği
├── setup.exe / uninstall.exe # Kurulum / kaldırma yardımcı yürütülebilir dosyaları
├── kripto_entegre.reg      # Manuel kayıt defteri entegrasyon şablonu
└── README.md               # Proje tanıtım ve kullanım kılavuzu
```

---

## 🔒 Güvenlik Detayları

*   **Kimlik Doğrulamalı Şifreleme (AEAD):** AES-GCM şifreleme modu kullanıldığı için, şifreli dosya üzerinde yapılacak herhangi bir yetkisiz değiştirme veya bozulma (tamper) şifre çözme aşamasında tespit edilir ve işlem iptal edilir.
*   **Brute-Force Koruması:** Anahtar türetiminde kullanılan PBKDF2HMAC algoritması 600.000 iterasyon kullandığı için, deneme-yanılma (brute-force) saldırılarına karşı son derece dayanıklıdır.
*   **Güvenli Dosya Silme:** Düzenleme modunda oluşturulan geçici şifresiz dosyalar, işlem bittiğinde veya iptal edildiğinde diskten tamamen silinir.

---

## 👤 Geliştirici

Bu proje **Eren Gündüzvar** tarafından geliştirilmiştir.
