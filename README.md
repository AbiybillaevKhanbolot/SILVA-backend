# SILVA-backend

Бэкенд-инфраструктура проекта **SILVA** на **Firebase**.

Репозиторий хранит серверную логику, правила безопасности и конфигурацию окружения для продакшена.

## Что находится в репозитории

- Cloud Functions (бизнес-логика и интеграции, включая платежи)
- Firestore security rules (доступ к данным по ролям)
- Firebase Storage rules (доступ к файлам и медиа)
- Индексы и конфигурация Firestore
- Скрипты деплоя и служебные утилиты
- Документация по настройке и выпуску

## Технологический стек

- **Firebase Authentication**
- **Cloud Firestore**
- **Cloud Functions** (Node.js/TypeScript)
- **Firebase Storage**
- **Firebase Hosting** (если используется для backend endpoints/proxy)
- **Firebase CLI**

## Структура репозитория

- `functions/` — Cloud Functions (основная серверная логика)
- `firestore.rules` — правила доступа Firestore
- `firestore.indexes.json` — индексы Firestore
- `storage.rules` — правила доступа Storage
- `firebase.json` — конфигурация проекта Firebase
- `.firebaserc` — project aliases (без секретов)
- `scripts/` — вспомогательные скрипты деплоя/проверок
- `docs/` — техническая документация
- `.env.example` — шаблон переменных окружения (без реальных ключей)

## Принципы безопасности

- Никогда не коммитить секреты (`.env`, private keys, service-account JSON и т.д.)
- Хранить секреты только в защищенных переменных окружения (CI/CD, Secret Manager)
- Все операции записи и чтения ограничивать правилами Firestore/Storage
- Доступ к административным операциям — только через проверенные роли (custom claims)
- Минимизировать права сервисных аккаунтов

## Быстрый старт

1. Установить зависимости:
   - `npm install` (в корне и/или в `functions/`, в зависимости от структуры)
2. Авторизоваться в Firebase:
   - `firebase login`
3. Выбрать проект:
   - `firebase use <project-id>`
4. Запустить локально (по необходимости):
   - `firebase emulators:start`
5. Деплой:
   - `firebase deploy`

## Переменные окружения

Фронтенду обычно нужны только публичные Firebase-переменные:

- `VITE_FIREBASE_API_KEY`
- `VITE_FIREBASE_AUTH_DOMAIN`
- `VITE_FIREBASE_PROJECT_ID`
- `VITE_FIREBASE_STORAGE_BUCKET`
- `VITE_FIREBASE_MESSAGING_SENDER_ID`
- `VITE_FIREBASE_APP_ID`

> Секретные ключи и токены не должны попадать во frontend runtime и в git.

## Роли и доступ

Рекомендуемые роли пользователей:

- `guest` — базовый доступ на чтение публичных данных
- `owner` — доступ к собственным сущностям/операциям
- `admin` — расширенные права управления

Реализация ролей:
- через Firebase Auth custom claims
- с обязательной проверкой ролей в Cloud Functions и security rules

## Платежи (если подключены)

Платежная логика должна выполняться в Cloud Functions:

- создание платежа
- проверка статуса платежа
- webhook-обработчики

Ключи провайдера платежей хранятся только в защищенном окружении (не в репозитории).

## Рекомендации перед продакшен-деплоем

- проверить Firestore rules на least-privilege
- проверить Storage rules для приватных/публичных путей
- убедиться, что все секреты вынесены из кода
- прогнать smoke-тесты по ролям `guest/owner/admin`
- проверить логи Cloud Functions и алерты мониторинга
