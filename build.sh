#!/bin/bash
set -e

echo "🚀 Building Flutter Web App for Vercel..."

# Install Flutter if not available
if ! command -v flutter &> /dev/null; then
    echo "📦 Installing Flutter SDK..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 /tmp/flutter
    export PATH="/tmp/flutter/bin:$PATH"
    flutter config --enable-web
fi

echo "🔧 Flutter Doctor Check..."
flutter doctor

echo "📦 Getting dependencies..."
flutter pub get

echo "🏗️ Building for production..."

# Load environment variables from .env file if it exists
if [ -f ".env" ]; then
  echo "📦 Loading environment variables from .env..."
  export $(grep -v '^#' .env | xargs)
fi

# Also try assets/.env for backward compatibility
if [ -f "assets/.env" ]; then
  echo "📦 Loading environment variables from assets/.env..."
  export $(grep -v '^#' assets/.env | xargs)
fi

# Build with environment variables
flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}" \
  --dart-define=SUPABASE_STORAGE_BUCKET="${SUPABASE_STORAGE_BUCKET:-gtm-assets-public}" \
  --dart-define=RATING_API_BASE_URL="${RATING_API_BASE_URL:-https://api.gtm.baby}" \
  --dart-define=SUPABASE_AI_BUCKET="${SUPABASE_AI_BUCKET:-gtm-ai-uploads}" \
  --dart-define=SUPABASE_AI_FOLDER="${SUPABASE_AI_FOLDER:-img}" \
  --dart-define=TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}" \
  --dart-define=WEBAPP_VERSION="${WEBAPP_VERSION:-1.0.9}"

echo "✅ Build completed successfully!"
echo "📊 Build size:"
du -sh build/web/

echo "🌐 Build ready for deployment in build/web/"