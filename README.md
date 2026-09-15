# DriveMind — тренажёр ПДД

Мобильное приложение для подготовки к экзамену ПДД: билеты, экзамен как в ГАИ, марафон, темы, детский режим, ИИ-инструктор, статистика и достижения. Офлайн-first, тёмная тема.

## Скриншоты
Папка `screenshots/`:
- `home.png` — главный экран, streak, факт дня
- `exam.png` — экзамен, 20 вопросов и таймер
- `instructor.png` — ИИ-инструктор, разбор ошибок
- `kids.png` — детский режим

## Возможности
- Экзамен ГАИ: 20 вопросов / 20 минут / до 2 ошибок; билеты 1–40, марафон на 800 вопросов, темы, работа над ошибками, карта ошибок
- ИИ-инструктор: разбор ошибок по темам, план подготовки, детские объяснения; работает с Ollama Cloud и локальным LM Studio/Ollama, без сети — локальные подсказки
- Прогресс: streak, монеты, магазин тем (12 пресетов), достижения, статистика по темам, PDF-отчёт, экспорт/импорт прогресса в JSON
- Детский режим: простые формулировки, озвучка, крупные кнопки
- Напоминания: локальное уведомление в 19:00, умные напоминания при перерыве

## Стек
Flutter 3.16+ / Dart 3.2 · Riverpod · Hive + SharedPreferences · flutter_secure_storage · http · google_fonts · flutter_tts · flutter_local_notifications · fl_chart · pdf/printing · share_plus · image_picker

## Структура
```
lib/app.dart            # роуты, темы, DynamicColor
lib/core/llm/           # чат, список моделей, разбор ошибок, детские объяснения
lib/core/storage/       # профиль, streak, квесты
lib/core/notifications/ # локальные напоминания
lib/core/theme/         # пресеты тем, градиенты
lib/features/exam|tickets|marathon|trainer|themes|mistakes|stats|instructor|kids|...
lib/data/models/        # Question, Profile
assets/data/            # вопросы и знаки (в репо — демо-набор, см. ниже)
```

## Запуск
```bash
flutter pub get
flutter run
```

Сборка релиза:
```bash
# заполнить ключ по шаблону android/key.properties.example -> android/key.properties
flutter build appbundle --release
```

Безопасность: токен LLM — в зашифрованном хранилище, сеть — только HTTPS (исключение cleartext — только localhost/10.0.2.2 для локального сервера), подпись релиза — через `key.properties`, который в репозиторий не входит.

## Данные
В репозитории — демонстрационный набор (билет №1, часть знаков и детских вопросов). Детали — `assets/data/README_DATASET.md`. Учебный проект, не является официальным приложением ГИБДД/МВД.
