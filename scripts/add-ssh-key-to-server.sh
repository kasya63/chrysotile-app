#!/bin/bash
# Однократно добавляет ваш публичный ключ на сервер chrysotile.
# После этого вход по паролю можно отключить.

set -euo pipefail

KEY_FILE="${HOME}/.ssh/id_chrysotile.pub"
SERVER="root@109.235.118.78"

if [[ ! -f "$KEY_FILE" ]]; then
  echo "Ключ не найден: $KEY_FILE"
  echo "Создайте его командой:"
  echo "  ssh-keygen -t ed25519 -f ~/.ssh/id_chrysotile -C \"adlet@chrysotile\""
  exit 1
fi

echo "Добавляем ключ на сервер $SERVER"
echo "Сейчас попросит пароль root (последний раз)."

ssh-copy-id -i "$KEY_FILE" "$SERVER"

echo ""
echo "Проверка входа по ключу:"
ssh -i "${HOME}/.ssh/id_chrysotile" "$SERVER" "echo 'OK: вход по ключу работает'"

echo ""
echo "Готово. Теперь можно подключаться так:"
echo "  ssh chrysotile"
