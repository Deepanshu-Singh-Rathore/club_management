#!/usr/bin/env bash
# Exit immediately if a command exits with a non-zero status
set -e

echo "============================================="
echo "==> ClubSphere Frontend - Render Build Script"
echo "============================================="

# Cache Flutter in user home directory
FLUTTER_HOME="$HOME/flutter"

if [ ! -d "$FLUTTER_HOME" ]; then
  echo "==> Cloning Flutter SDK (stable channel)..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_HOME"
else
  echo "==> Flutter SDK found in $FLUTTER_HOME"
fi

export PATH="$PATH:$FLUTTER_HOME/bin"

echo "==> Flutter version:"
flutter --version

echo "==> Configuring Flutter Web..."
flutter config --enable-web --no-analytics

echo "==> Fetching dependencies..."
flutter pub get

echo "==> Building Flutter Web Release..."
if [ -n "$API_URL" ]; then
  echo "==> Embedding API_URL: $API_URL"
  flutter build web --release --dart-define=API_URL="$API_URL"
else
  echo "==> No API_URL environment variable provided. Using default."
  flutter build web --release
fi

echo "============================================="
echo "==> Build successful! Output directory: build/web"
echo "============================================="
