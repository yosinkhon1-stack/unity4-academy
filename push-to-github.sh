#!/bin/bash

echo "🎯 Unity4 Academy - GitHub'a Yükleme Scripti"
echo "=============================================="
echo ""

# Renk kodları
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}📋 Bu script kodunuzu GitHub'a yükleyecek${NC}"
echo ""
echo "Önce GitHub'da bir repository oluşturmanız gerekiyor:"
echo ""
echo -e "${BLUE}1. https://github.com/new adresine gidin${NC}"
echo -e "${BLUE}2. Repository adı: unity4-academy${NC}"
echo -e "${BLUE}3. Public veya Private seçin${NC}"
echo -e "${BLUE}4. 'Create repository' butonuna tıklayın${NC}"
echo ""
echo -e "${YELLOW}Repository oluşturdunuz mu? (y/n)${NC}"
read -r response

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Önce GitHub repository oluşturun!${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}GitHub kullanıcı adınızı girin:${NC}"
read -r username

if [ -z "$username" ]; then
    echo -e "${RED}❌ Kullanıcı adı boş olamaz!${NC}"
    exit 1
fi

echo ""

echo -e "${YELLOW}📤 GitHub'a yükleniyor...${NC}"

# Git başlat
if [ ! -d ".git" ]; then
    echo "Git repository başlatılıyor..."
    git init
    git branch -M main
fi

# Dosyaları ekle ve commitle
if [ -z "$(git status --porcelain)" ]; then
    echo "Değişiklik yok, commit atlanıyor."
else
    echo "Dosyalar ekleniyor ve commitleniyor..."
    git add .
    git commit -m "Initial commit - Unity4 Academy" || echo "Commit oluşturulamadı (zaten güncel olabilir)"
fi

# Remote ekle
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/$username/unity4-academy.git"

# Branch ayarla
git branch -M main

# Push
echo ""
echo -e "${YELLOW}Kodu yüklüyorum... (GitHub şifreniz istenebilir)${NC}"
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Kod başarıyla GitHub'a yüklendi!${NC}"
    echo ""
    echo -e "${YELLOW}📝 ŞİMDİ YAPMANIZ GEREKENLER:${NC}"
    echo ""
    echo "1️⃣  Firebase Service Account Oluşturun:"
    echo "   - https://console.firebase.google.com adresine gidin"
    echo "   - Unity4 Academy projesini seçin"
    echo "   - Project Settings > Service Accounts"
    echo "   - 'Generate New Private Key' butonuna tıklayın"
    echo "   - JSON dosyasını indirin ve içeriğini kopyalayın"
    echo ""
    echo "2️⃣  GitHub Secret Ekleyin:"
    echo "   - https://github.com/$username/unity4-academy/settings/secrets/actions"
    echo "   - 'New repository secret' butonuna tıklayın"
    echo "   - Name: FIREBASE_SERVICE_ACCOUNT"
    echo "   - Value: JSON içeriğini yapıştırın"
    echo "   - 'Add secret' butonuna tıklayın"
    echo ""
    echo "3️⃣  Deployment'ı Başlatın:"
    echo "   - https://github.com/$username/unity4-academy/actions"
    echo "   - 'Build and Deploy to Firebase' workflow'unu seçin"
    echo "   - 'Run workflow' butonuna tıklayın"
    echo ""
    echo -e "${GREEN}🎉 Tamamlandığında uygulamanız yayında olacak!${NC}"
    echo -e "${GREEN}🌐 URL: https://unity4-academy.web.app${NC}"
else
    echo ""
    echo -e "${RED}❌ Yükleme başarısız oldu!${NC}"
    echo ""
    echo "Muhtemel nedenler:"
    echo "- GitHub şifreniz yanlış"
    echo "- Repository adı yanlış"
    echo "- İnternet bağlantısı sorunu"
    echo ""
    echo "Tekrar denemek için bu scripti çalıştırın."
fi
