# Chrysotile Mobile App

Flutter-приложение для чтения новостей с [chrysotile.kz](https://chrysotile.kz).

## Локальный запуск

```bash
export PATH="$HOME/try_flutter/flutter/bin:$PATH"
cd ~/Projects/chrysotile_app
flutter pub get
flutter run
```

## API

Бэкенд: `https://chrysotile.kz/wp-json/chrysotile/v1`

- `GET /home` — главная лента
- `GET /posts/{id}` — статья
- `GET /feed?category=slug&page=1` — лента по рубрике
- `GET /categories` — список рубрик
- `GET /search?q=...` — поиск
- `POST /posts/{id}/view` — учёт просмотра

Исходник API-плагина: `wordpress/mu-plugins/chrysotile-mobile-api.php`

## Что уже есть в приложении

- Нижняя навигация: Главная / Рубрики / Поиск / Закладки / Профиль
- Поиск с debounce и пагинацией
- Закладки локально (офлайн) + кнопка на экране статьи
- Рубрики и лента категории
- Светлая / тёмная / системная тема

## Сервер

Скрипты в `scripts/`:

- `add-ssh-key-to-server.sh` — добавить SSH-ключ
- `server-bootstrap.sh` — swap, UFW, Redis, WP Object Cache

Подключение:

```bash
ssh chrysotile
```

## Следующие шаги

1. Авторизация (email / Google / Apple + JWT на WP)
2. Комментарии с премодерацией
3. Push-уведомления (Firebase)
4. Настройки шрифта и подписки на рубрики
