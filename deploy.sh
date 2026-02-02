#!/bin/bash

echo "🚀 Unity4 Academy - Deployment Script"
echo "======================================"
echo ""

# Renk kodları
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Hata durumunda çık
set -e

# 1. Flutter kontrolü
echo -e "${YELLOW}📦 Flutter kontrolü yapılıyor...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter bulunamadı!${NC}"
    exit 1
fi

flutter --version
echo ""

# 2. Temizlik
echo -e "${YELLOW}🧹 Eski build dosyaları temizleniyor...${NC}"
flutter clean
echo ""

# 3. Bağımlılıkları güncelle
echo -e "${YELLOW}📥 Bağımlılıklar güncelleniyor...${NC}"
flutter pub get
echo ""

# 4. Web build oluştur
echo -e "${YELLOW}🔨 Web build oluşturuluyor (bu birkaç dakika sürebilir)...${NC}"
flutter build web --release
echo ""

# 5. Build kontrolü
if [ ! -d "build/web" ]; then
    echo -e "${RED}❌ Build başarısız oldu!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build başarıyla oluşturuldu!${NC}"
echo ""

# 6. Firebase deploy
echo -e "${YELLOW}🌐 Firebase'e deploy ediliyor...${NC}"

# Firebase CLI kontrolü
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI bulunamadı!${NC}"
    echo "Yüklemek için: npm install -g firebase-tools"
    exit 1
fi

firebase deploy --only hosting

echo ""
echo -e "${GREEN}✅ Deployment tamamlandı!${NC}"
echo -e "${GREEN}🎉 Uygulamanız yayında!${NC}"
echo ""
echo "URL: https://unity4-academy.web.app"
echo "veya: https://unity4-academy.firebaseapp.com"
