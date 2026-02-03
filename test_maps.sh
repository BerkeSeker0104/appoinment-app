#!/bin/bash

# 🗺️ Google Maps Test Script
# Bu script harita sorunlarını test etmek için gerekli adımları çalıştırır

echo "🧹 Cleaning Flutter project..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo ""
echo "🍎 iOS için CocoaPods güncelleniyor..."
cd ios
pod deintegrate
pod install
cd ..

echo ""
echo "✅ Temizlik ve kurulum tamamlandı!"
echo ""
echo "📱 Test etmek için:"
echo ""
echo "iOS için:"
echo "  flutter run -d \"iPhone\""
echo ""
echo "Android için:"
echo "  flutter run -d \"Android\""
echo ""
echo "🔍 Loglarda aranacak kelimeler:"
echo "  ✅ \"Map initialized and ready to display\""
echo "  ✅ \"Markers updated successfully\""
echo "  ❌ \"Lost connection to device\" (CRASH!)"
echo "  ❌ \"Maps SDK is not authorized\" (API sorunu!)"
echo ""
echo "📖 Detaylı rehber için: GOOGLE_MAPS_SETUP.md"

