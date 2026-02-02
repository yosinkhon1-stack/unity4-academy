# Unity4 Academy - Otomatik Deployment Kurulumu

Bu proje GitHub Actions kullanarak otomatik olarak Firebase Hosting'e deploy edilir.

## 🚀 Kurulum Adımları

### 1. GitHub Repository Oluşturun

1. GitHub'da yeni bir repository oluşturun (örn: `unity4-academy`)
2. Repository'yi public veya private yapabilirsiniz

### 2. Firebase Service Account Oluşturun

1. Firebase Console'a gidin: https://console.firebase.google.com
2. Unity4 Academy projesini seçin
3. ⚙️ **Project Settings** > **Service Accounts** sekmesine gidin
4. **Generate New Private Key** butonuna tıklayın
5. İndirilen JSON dosyasını açın ve içeriğini kopyalayın

### 3. GitHub Secrets Ekleyin

1. GitHub repository'nizde **Settings** > **Secrets and variables** > **Actions** bölümüne gidin
2. **New repository secret** butonuna tıklayın
3. Name: `FIREBASE_SERVICE_ACCOUNT`
4. Value: Kopyaladığınız JSON içeriğini yapıştırın
5. **Add secret** butonuna tıklayın

### 4. Kodu GitHub'a Yükleyin

Aşağıdaki komutları terminalden çalıştırın:

```bash
cd "/Users/k/unity4_app1 kopyası"

# Git yapılandırması (ilk kez kullanıyorsanız)
git config --global user.email "sizin@email.com"
git config --global user.name "Adınız"

# Dosyaları ekleyin
git add .
git commit -m "Initial commit - Unity4 Academy"

# GitHub repository'nizi ekleyin (YOUR_USERNAME yerine GitHub kullanıcı adınızı yazın)
git remote add origin https://github.com/YOUR_USERNAME/unity4-academy.git

# Ana branch'i ayarlayın
git branch -M main

# Kodu yükleyin
git push -u origin main
```

### 5. Otomatik Deployment

Artık her `git push` yaptığınızda:
- ✅ Otomatik olarak Flutter web build alınacak
- ✅ Firebase Hosting'e deploy edilecek
- ✅ https://unity4-academy.web.app adresinde yayınlanacak

## 📝 Notlar

- İlk deployment 5-10 dakika sürebilir
- GitHub Actions sekmesinden deployment durumunu takip edebilirsiniz
- Hata durumunda Actions loglarını kontrol edin

## 🔧 Manuel Deployment (Opsiyonel)

Eğer lokal bilgisayarınızda build alabiliyorsanız:

```bash
flutter build web --release
firebase deploy --only hosting
```

## 📱 Uygulama URL'leri

- **Ana Site:** https://unity4-academy.web.app
- **Alternatif:** https://unity4-academy.firebaseapp.com
