#!/usr/bin/env bash
# Сборка и загрузка iOS-версии в App Store Connect.
#
# Использование:
#   scripts/release_ios.sh                  # build+1 (версия не меняется), сборка, загрузка
#   scripts/release_ios.sh --name 1.0.3     # новая версия 1.0.3+1
#   scripts/release_ios.sh --no-upload      # только собрать .ipa
#   scripts/release_ios.sh --no-git         # не коммитить / не тегировать / не пушить
#
# Для загрузки нужны (один раз):
#   export APPLE_ID="ваш@apple.id"
#   xcrun altool --store-password-in-keychain-item AC_PASSWORD -u "$APPLE_ID" -p "xxxx-xxxx-xxxx-xxxx"
# где пароль — app-specific password из https://account.apple.com (Вход и безопасность).
set -euo pipefail
cd "$(dirname "$0")/.."

NEW_NAME=""; UPLOAD=1; GIT=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) NEW_NAME="${2:?укажите версию, например 1.0.3}"; shift 2 ;;
    --no-upload) UPLOAD=0; shift ;;
    --no-git) GIT=0; shift ;;
    *) echo "Неизвестный параметр: $1"; exit 1 ;;
  esac
done

command -v flutter >/dev/null || { echo "flutter не найден"; exit 1; }
command -v xcodebuild >/dev/null || { echo "Xcode не найден"; exit 1; }

# --- версия из pubspec.yaml ---
CURRENT="$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}')"
NAME="${CURRENT%%+*}"
BUILD="0"; [[ "$CURRENT" == *+* ]] && BUILD="${CURRENT##*+}"
if [[ -n "$NEW_NAME" && "$NEW_NAME" != "$NAME" ]]; then
  NAME="$NEW_NAME"; BUILD=1
else
  # если номера сборки не было (например "1.0.2"), начинаем с 2, чтобы он был больше "1.0.2"
  [[ "$BUILD" -lt 1 ]] && BUILD=2 || BUILD=$((BUILD + 1))
fi
VERSION="$NAME+$BUILD"
sed -i '' -E "s/^version: .*/version: $VERSION/" pubspec.yaml
echo "==> Версия: $VERSION"

# --- сборка ---
flutter pub get
(cd ios && pod install --repo-update)
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
IPA="$(ls -t build/ios/ipa/*.ipa | head -1)"
echo "==> Собрано: $IPA"

# --- загрузка ---
if [[ "$UPLOAD" == 1 ]]; then
  : "${APPLE_ID:?задайте APPLE_ID (export APPLE_ID=ваш@apple.id)}"
  xcrun altool --upload-app --type ios --file "$IPA" \
    --username "$APPLE_ID" --password "@keychain:AC_PASSWORD"
  echo "==> Загружено. Обработка в App Store Connect займёт 10–30 минут."
fi

# --- git ---
if [[ "$GIT" == 1 ]]; then
  git add pubspec.yaml
  git commit -m "Release iOS $VERSION" || true
  git tag -f "v$VERSION"
  git push origin HEAD --tags
fi
echo "==> Готово: $VERSION"
echo "Напоминание: в App Store Connect поле «Версия» должно быть $NAME."
