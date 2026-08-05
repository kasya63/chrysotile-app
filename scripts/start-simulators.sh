#!/bin/bash
# Запуск iPhone Simulator + Android Pixel_7 для Chrysotile.
set -euo pipefail

export PATH="$HOME/try_flutter/flutter/bin:$HOME/Library/Android/sdk/platform-tools:$HOME/Library/Android/sdk/emulator:$PATH"
export ANDROID_HOME="$HOME/Library/Android/sdk"

echo "==> iPhone Simulator (iPhone 17 Pro)"
open -a Simulator
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || true
xcrun simctl bootstatus "iPhone 17 Pro" -b

echo ""
echo "==> Android Emulator (Pixel_7)"
if ! adb devices | grep -q emulator; then
  nohup "$ANDROID_HOME/emulator/emulator" \
    -avd Pixel_7 \
    -no-snapshot-load \
    -gpu auto \
    -netdelay none \
    -netspeed full \
    >/tmp/chrysotile-pixel7.log 2>&1 &
  echo "Запускаю Pixel_7 (pid $!). Жди 1–2 минуты..."
  for i in $(seq 1 36); do
    sleep 5
    if adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' | grep -q 1; then
      echo "Android готов."
      break
    fi
    printf "."
  done
  echo ""
else
  echo "Эмулятор Android уже запущен."
fi

echo ""
echo "==> Устройства Flutter:"
flutter devices

echo ""
echo "Запуск приложения:"
echo "  cd ~/Projects/chrysotile_app"
echo "  flutter run -d <device-id>     # конкретное устройство"
echo "  flutter run                   # если одно устройство"
echo ""
echo "iPhone:  flutter run -d \$(flutter devices | awk '/iPhone 17 Pro/{print \$5; exit}')"
echo "Android: flutter run -d emulator-5554"
