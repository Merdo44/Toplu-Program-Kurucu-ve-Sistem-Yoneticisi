# 🚀 Toplu Program Kurucu ve Sistem Yöneticisi (System Manager Pro)

Windows işletim sistemleri için geliştirilmiş, modern Fluent Design arayüzüne sahip gelişmiş toplu yazılım kurulum, yönetim ve sistem optimizasyon aracı.

---

## ✨ Temel Özellikler

- **📦 Kapsamlı Yazılım Kataloğu:** Tarayıcılardan geliştirici araçlarına, multimedyadan sistem bileşenlerine kadar 100+ güncel yazılım.
- **🛍️ Çift Kaynak Desteği:** WinGet / Web ve Microsoft Store (MS Store) kaynakları arasında tek tıkla geçiş (Varsayılan: Normal Web).
- **📋 Kurulum Kuyruğu & Sürükle-Bırak:** Kurulum sırasını dilediğiniz gibi düzenleyebilir, kuyruktayken kaynak değiştirebilirsiniz.
- **🧹 Gelişmiş Disk & Sistem Temizleyici:** 
  - Windows Temp, Kullanıcı Temp (%TEMP%), Prefetch, Geri Dönüşüm Kutusu
  - Windows Update indirme kalıntıları, Küçük Resim (Thumbnails) önbellekleri
  - Çökme raporları (WER) ve sistem kurulum logları
  - Yüklü web tarayıcılarının (Chrome, Edge, Firefox, Brave, Opera) önbellek temizliği
- **🛡️ Windows Defender & Tehdit Koruması:** Sessiz arka planda çalışan canlı sayaçlı Fluent tarama motoru (Hızlı, Tam, Özel tarama ve imza güncelleme).
- **🎨 Modern & Duyarlı Tasarım:** WPF tabanlı, koyu/açık tema uyumlu, yüksek çözünürlüklü logolar ve akıcı animasyonlar.

---

## 🛠️ Gereksinimler & Çalıştırma

1. **PowerShell:** Windows PowerShell 5.1 veya üzeri (Yönetici yetkileriyle).
2. **WinGet:** Windows Paket Yöneticisi (Varsayılan olarak Windows 10/11 ile birlikte gelir).
3. **Çalıştırma:**
   `powershell
   powershell.exe -ExecutionPolicy Bypass -File .\SystemManagerPro.ps1
   `

---

## 📦 Derleme (.exe Yapma)

Uygulamayı bağımsız bir .exe haline getirmek için ps2exe modülü kullanılır:
`cmd
BUILD_SystemManagerPro_EXE.bat
`
