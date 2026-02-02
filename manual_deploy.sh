#!/bin/bash
set -e

echo "🚀 Starting Deployment Process..."

# 1. Clean build directory manually
echo "cleaning build..."
rm -rf build

# 2. Get dependencies
echo "getting dependencies..."
flutter pub get

# 3. Build web app
echo "building web app..."
# Using release build. If this fails due to memory, we can try without canvaskit or with less optimization
flutter build web --release

# 4. Deploy to Firebase
echo "deploying to firebase..."
firebase deploy --only hosting

echo "✅ Deployment Complete!"
