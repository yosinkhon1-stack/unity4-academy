# 🚀 Unity4 Academy - Otomatik Deployment Kurulum Rehberi

## ✅ Tamamlanan Adımlar

- ✅ Git repository başlatıldı
- ✅ GitHub Actions workflow dosyası oluşturuldu
- ✅ Deployment scriptleri hazırlandı
- ✅ Tüm dosyalar commit edildi

## 📋 Şimdi Yapmanız Gerekenler

### Adım 1: GitHub Repository Oluşturun (2 dakika)

1. **GitHub'a gidin:** https://github.com/new
2. **Repository ayarları:**
   - Repository name: `unity4-academy`
   - Description: "Unity4 Academy - Eğitim Yönetim Sistemi"
   - Public veya Private (tercihinize bağlı)
   - ❌ README, .gitignore veya license **EKLEMEYIN** (zaten var)
3. **"Create repository"** butonuna tıklayın

### Adım 2: Kodu GitHub'a Yükleyin (1 dakika)

Terminal'de şu komutu çalıştırın:

```bash
cd "/Users/k/unity4_app1 kopyası"
./push-to-github.sh
```

Script size adım adım rehberlik edecek.

**Alternatif (Manuel):**

```bash
cd "/Users/k/unity4_app1 kopyası"

# GitHub kullanıcı adınızı buraya yazın
git remote add origin https://github.com/KULLANICI_ADINIZ/unity4-academy.git
git branch -M main
git push -u origin main
```

### Adım 3: Firebase Service Account Oluşturun (3 dakika)

1. **Firebase Console'a gidin:** https://console.firebase.google.com
2. **Unity4 Academy** projesini seçin
3. Sol üstteki **⚙️ (ayarlar)** ikonuna tıklayın
4. **Project Settings** seçin
5. **Service Accounts** sekmesine gidin
6. **Generate New Private Key** butonuna tıklayın
7. Uyarıyı onaylayın ve JSON dosyasını indirin
8. İndirilen JSON dosyasını bir metin editörü ile açın
9. **Tüm içeriği kopyalayın** (Cmd+A, Cmd+C)

### Adım 4: GitHub Secret Ekleyin (2 dakika)

1. GitHub repository'nize gidin
2. **Settings** sekmesine tıklayın
3. Sol menüden **Secrets and variables** > **Actions** seçin
4. **New repository secret** butonuna tıklayın
5. Formu doldurun:
   - **Name:** `FIREBASE_SERVICE_ACCOUNT`
   - **Value:** Kopyaladığınız JSON içeriğini yapıştırın
6. **Add secret** butonuna tıklayın

### Adım 5: Deployment'ı Başlatın (1 dakika)

1. GitHub repository'nizde **Actions** sekmesine gidin
2. **"Build and Deploy to Firebase"** workflow'unu göreceksiniz
3. İlk push sonrası otomatik başlayacak
4. Veya manuel başlatmak için:
   - Workflow'u seçin
   - **Run workflow** butonuna tıklayın
   - **Run workflow** (yeşil buton) onaylayın

### Adım 6: Sonucu Kontrol Edin (5-10 dakika)

1. **Actions** sekmesinde deployment ilerlemesini izleyin
2. Yeşil ✅ işareti görünce deployment tamamlanmıştır
3. Uygulamanız şu adreslerde yayında:
   - 🌐 **Ana URL:** https://unity4-academy.web.app
   - 🌐 **Alternatif:** https://unity4-academy.firebaseapp.com

## 🎯 Gelecekte Güncelleme Yapmak

Artık her kod değişikliğinde otomatik deployment yapılacak:

```bash
cd "/Users/k/unity4_app1 kopyası"

# Değişikliklerinizi yapın...

# Sonra:
git add .
git commit -m "Açıklama mesajınız"
git push
```

GitHub Actions otomatik olarak:
1. ✅ Flutter web build alacak
2. ✅ Firebase'e deploy edecek
3. ✅ Uygulamanızı güncelleyecek

## 🆘 Sorun Giderme

### "Permission denied" hatası
```bash
chmod +x push-to-github.sh
./push-to-github.sh
```

### GitHub şifre soruyor
GitHub artık şifre yerine **Personal Access Token** kullanıyor:
1. https://github.com/settings/tokens adresine gidin
2. **Generate new token (classic)** seçin
3. `repo` yetkisini verin
4. Token'ı kopyalayın
5. Şifre yerine bu token'ı kullanın

### Deployment başarısız oluyor
1. GitHub Actions loglarını kontrol edin
2. Firebase Service Account doğru mu kontrol edin
3. Firebase projesinde Hosting aktif mi kontrol edin

## 📞 Yardım

Sorun yaşarsanız:
- GitHub Actions loglarını kontrol edin
- Firebase Console'da hata mesajlarına bakın
- DEPLOYMENT.md dosyasını okuyun

## 🎉 Tebrikler!

Artık profesyonel bir CI/CD pipeline'ınız var! 🚀
