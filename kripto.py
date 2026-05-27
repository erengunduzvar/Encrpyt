import os
import sys
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives import hashes

def anahtar_uret(parola: str, tuz: bytes) -> bytes:
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=tuz,
        iterations=600_000,
    )
    return kdf.derive(parola.encode())

def dosya_sifrele(dosya_yolu: str, parola: str) -> tuple[bool, str]:
    if not os.path.exists(dosya_yolu):
        msg = f"Hata: '{dosya_yolu}' dosyası bulunamadı!"
        print(f"❌ {msg}")
        return False, msg

    try:
        tuz = os.urandom(16)
        nonce = os.urandom(12)
        
        anahtar = anahtar_uret(parola, tuz)
        aesgcm = AESGCM(anahtar)
        
        with open(dosya_yolu, 'rb') as f:
            orijinal_veri = f.read()
            
        sifreli_veri = aesgcm.encrypt(nonce, orijinal_veri, None)
        
        yeni_dosya = dosya_yolu + ".enc"
        with open(yeni_dosya, 'wb') as f:
            f.write(tuz + nonce + sifreli_veri)
            
        os.remove(dosya_yolu)
        msg = f"Dosya şifrelendi ve orijinali silindi: {yeni_dosya}"
        print(f"🔒 {msg}")
        return True, msg
    except Exception as e:
        msg = f"Şifreleme sırasında bir hata oluştu: {str(e)}"
        print(f"❌ {msg}")
        return False, msg

def dosya_sifre_coz(sifreli_dosya_yolu: str, parola: str) -> tuple[bool, str]:
    if not os.path.exists(sifreli_dosya_yolu):
        msg = f"Hata: '{sifreli_dosya_yolu}' dosyası bulunamadı!"
        print(f"❌ {msg}")
        return False, msg

    try:
        with open(sifreli_dosya_yolu, 'rb') as f:
            tuz = f.read(16)
            nonce = f.read(12)
            sifreli_veri = f.read()
            
        anahtar = anahtar_uret(parola, tuz)
        aesgcm = AESGCM(anahtar)
        
        cozulmus_veri = aesgcm.decrypt(nonce, sifreli_veri, None)
        
        orijinal_dosya_yolu = sifreli_dosya_yolu.replace(".enc", "")
        with open(orijinal_dosya_yolu, 'wb') as f:
            f.write(cozulmus_veri)
            
        os.remove(sifreli_dosya_yolu)
        msg = f"Şifre çözüldü, orijinal dosya geri geldi: {orijinal_dosya_yolu}"
        print(f"🔓 {msg}")
        return True, msg
        
    except Exception:
        msg = "Hata: Yanlış parola veya bozuk dosya!"
        print(f"❌ {msg}")
        return False, msg

def dosya_ac_ve_duzenle(sifreli_dosya_yolu: str, parola: str) -> tuple[bool, str]:
    if not os.path.exists(sifreli_dosya_yolu):
        msg = f"Hata: '{sifreli_dosya_yolu}' dosyası bulunamadı!"
        print(f"❌ {msg}")
        return False, msg

    try:
        with open(sifreli_dosya_yolu, 'rb') as f:
            tuz = f.read(16)
            nonce = f.read(12)
            sifreli_veri = f.read()
            
        anahtar = anahtar_uret(parola, tuz)
        aesgcm = AESGCM(anahtar)
        
        cozulmus_veri = aesgcm.decrypt(nonce, sifreli_veri, None)
        
        orijinal_dosya_yolu = sifreli_dosya_yolu.replace(".enc", "")
        with open(orijinal_dosya_yolu, 'wb') as f:
            f.write(cozulmus_veri)
            
    except Exception:
        msg = "Hata: Yanlış parola veya bozuk dosya!"
        print(f"❌ {msg}")
        return False, msg

    try:
        os.startfile(orijinal_dosya_yolu)
    except Exception as e:
        if os.path.exists(orijinal_dosya_yolu):
            os.remove(orijinal_dosya_yolu)
        return False, f"Dosya açılamadı: {str(e)}"

    import tkinter as tk
    from tkinter import messagebox
    
    root = tk.Tk()
    root.title("Kripto - Düzenleme Modu")
    
    # Pencerenin her zaman en üstte kalmasını sağlayalım
    root.attributes("-topmost", True)
    
    window_width = 440
    window_height = 180
    screen_width = root.winfo_screenwidth()
    screen_height = root.winfo_screenheight()
    position_top = int(screen_height/2 - window_height/2)
    position_right = int(screen_width/2 - window_width/2)
    root.geometry(f"{window_width}x{window_height}+{position_right}+{position_top}")
    
    def guvenli_kapat():
        # Pencereyi en üstte tutmaya devam etmesi için parent=root verdik
        if messagebox.askyesno("Kapat / İptal", "Değişiklikleri kaydetmeden çıkmak istiyor musunuz?\n(Geçici şifresiz dosya silinecektir!)", parent=root):
            if os.path.exists(orijinal_dosya_yolu):
                os.remove(orijinal_dosya_yolu)
            root.destroy()
            sys.exit(0)
            
    root.protocol("WM_DELETE_WINDOW", guvenli_kapat)
    
    label = tk.Label(root, text=f"'{os.path.basename(orijinal_dosya_yolu)}'\ngeçici olarak çözüldü ve açıldı.", font=("Arial", 10, "bold"), pady=10)
    label.pack()
    
    label_info = tk.Label(root, text="Düzenlemeniz bittiğinde dosyayı kaydedip kapatın,\nardından aşağıdaki butona basın.", font=("Arial", 9))
    label_info.pack()
    
    def kaydet_ve_sifrele():
        try:
            if not os.path.exists(orijinal_dosya_yolu):
                messagebox.showerror("Hata", "Orijinal dosya bulunamadı!", parent=root)
                root.destroy()
                sys.exit(1)
                
            tuz_yeni = os.urandom(16)
            nonce_yeni = os.urandom(12)
            anahtar_yeni = anahtar_uret(parola, tuz_yeni)
            aesgcm_yeni = AESGCM(anahtar_yeni)
            
            with open(orijinal_dosya_yolu, 'rb') as f:
                orijinal_veri_yeni = f.read()
                
            sifreli_veri_yeni = aesgcm_yeni.encrypt(nonce_yeni, orijinal_veri_yeni, None)
            
            with open(sifreli_dosya_yolu, 'wb') as f:
                f.write(tuz_yeni + nonce_yeni + sifreli_veri_yeni)
                
            os.remove(orijinal_dosya_yolu)
            messagebox.showinfo("Başarılı", "Dosya kaydedildi ve tekrar güvenli şekilde şifrelendi.", parent=root)
            root.destroy()
            
        except Exception as e:
            messagebox.showerror("Hata", f"Yeniden şifreleme hatası: {str(e)}", parent=root)
            
    btn_frame = tk.Frame(root)
    btn_frame.pack(pady=15)
            
    btn_save = tk.Button(btn_frame, text="Kaydet ve Tekrar Şifrele", command=kaydet_ve_sifrele, bg="#4CAF50", fg="white", font=("Arial", 10, "bold"), padx=10, pady=5)
    btn_save.pack(side=tk.LEFT, padx=10)
    
    btn_cancel = tk.Button(btn_frame, text="İptal Et", command=guvenli_kapat, bg="#f44336", fg="white", font=("Arial", 10, "bold"), padx=10, pady=5)
    btn_cancel.pack(side=tk.LEFT, padx=10)
    
    # os.startfile sonrası odağı ve en üstte olmayı garantilemek için gecikmeli olarak öne getirelim
    root.after(100, lambda: (root.lift(), root.focus_force()))
    
    root.mainloop()
    return True, "Dosya başarıyla şifrelendi."

# --- YENİ TERMİNAL VE GUI KONTROL MERKEZİ ---
if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("\n⚙️  KULLANIM REHBERİ ⚙️")
        print("---------------------------------------------")
        print("Dosya Şifrelemek (Lock) İçin:")
        print("  python kripto.py -l <dosya_adi> [parolaniz]")
        print("\nŞifre Çözmek (Unlock) İçin:")
        print("  python kripto.py -u <sifreli_dosya_adi> [parolaniz]")
        print("\nAçıp Düzenlemek (Open & Edit) İçin:")
        print("  python kripto.py -o <sifreli_dosya_adi> [parolaniz]")
        print("\nNot: Parola girilmezse grafik ekranı açılır.")
        print("---------------------------------------------\n")
        sys.exit(1)

    islem = sys.argv[1].lower()
    dosya = sys.argv[2]
    
    gui_modu = False
    parola = ""
    
    if len(sys.argv) >= 4:
        parola = sys.argv[3]
    else:
        gui_modu = True
        import tkinter as tk
        from tkinter import simpledialog, messagebox
        
        root = tk.Tk()
        root.withdraw()
        
        islem_adi = "Şifreleme" if islem == "-l" else ("Aç ve Düzenle" if islem == "-o" else "Şifre Çözme")
        show_char = None if islem == "-l" else "*"
        parola = simpledialog.askstring(
            f"Kripto - {islem_adi}", 
            f"Lütfen '{os.path.basename(dosya)}' için parolanızı girin:",
            show=show_char
        )
        if not parola:
            sys.exit(0)

    basarili = False
    sonuc_mesaji = ""
    
    if islem == "-l":
        basarili, sonuc_mesaji = dosya_sifrele(dosya, parola)
    elif islem == "-u":
        basarili, sonuc_mesaji = dosya_sifre_coz(dosya, parola)
    elif islem == "-o":
        basarili, sonuc_mesaji = dosya_ac_ve_duzenle(dosya, parola)
    else:
        sonuc_mesaji = "Geçersiz parametre! Şifrelemek için '-l', çözmek için '-u', düzenlemek için '-o' kullanın."
        print(f"❌ {sonuc_mesaji}")
        if gui_modu:
            messagebox.showerror("Hata", sonuc_mesaji)
        sys.exit(1)

    if gui_modu and islem != "-o": # -o zaten kendi arayüzünü yönetiyor
        if basarili:
            messagebox.showinfo("Başarılı", sonuc_mesaji)
        else:
            messagebox.showerror("Hata", sonuc_mesaji)