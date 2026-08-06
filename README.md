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
Push-плагин: `wordpress/mu-plugins/chrysotile-mobile-push.php`

## Что уже есть в приложении

- Нижняя навигация: Главная / Рубрики / Поиск / Закладки / Профиль
- Авторизация, профиль, обратная связь, комментарии
- Push-уведомления (Firebase)
- Закладки с папками, масштаб текста, светлая / тёмная тема
- Политика конфиденциальности и условия использования (Профиль)
- Иконка приложения и splash (`assets/icon.png`)

Перегенерация иконок/splash после смены логотипа:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Сервер

Скрипты в `scripts/`:

- `add-ssh-key-to-server.sh` — добавить SSH-ключ
- `server-bootstrap.sh` — swap, UFW, Redis, WP Object Cache

Подключение:

```bash
ssh chrysotile
```

## Юридические страницы (стор)

Тексты для App Store / Google Play лежат в `assets/legal/`:

- `privacy_policy_ru.md` → опубликовать на сайте как `https://chrysotile.kz/privacy-policy/`
- `terms_ru.md` → опубликовать как `https://chrysotile.kz/terms/`

В приложении: **Профиль → Политика / Условия**.

В консолях после публикации страниц:

- **App Store Connect** → App Privacy / App Information → Privacy Policy URL
- **Google Play Console** → Policy → App content → Privacy policy (и Data safety)

## Следующие шаги

1. Опубликовать privacy/terms на chrysotile.kz (если ещё не опубликованы)
2. Удаление аккаунта in-app + web (обязательно при наличии auth)
3. Release signing Android, store listing / скриншоты
4. App Privacy / Data safety / News declaration в сторах
