#!/bin/bash
# Clone Flutter SDK
git clone https://github.com/flutter/flutter.git --depth 1 -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Enable web
flutter config --enable-web

# Get dependencies and build
flutter pub get
flutter build web --release
