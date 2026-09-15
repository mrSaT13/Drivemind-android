# DriveMind — тренажёр ПДД (Flutter, портфолио)

Учебное мобильное приложение для подготовки к экзамену ПДД: билеты, экзамен как в ГАИ, марафон, темы, детский режим, ИИ-инструктор, статистика и достижения. Офлайн-first, тёмная тема.

> Портфолио-версия: полный код + обрезанный датасет-сэмпл (билет №1 = 20 вопросов, 8 знаков, 10 детских, 21 картинка). Полный датасет на 800 вопросов в репо не кладём специально — см. `assets/data/README_DATASET.md`.

## Скриншоты
Положи сюда 3-4 скрина или GIF (папка `screenshots/`):
- `screenshots/home.png` — главный экран, streak, факт дня
- `screenshots/exam.png` — экзамен 20 вопросов / таймер
- `screenshots/instructor.png` — чат с ИИ-инструктором, анализ ошибок
- `screenshots/kids.png` — детский режим

## Стек
Flutter 3.16+ / Dart 3.2, Riverpod 2.4, Hive + SharedPreferences, flutter_secure_storage (токен LLM), http, google_fonts, flutter_tts, flutter_local_notifications, fl_chart, pdf/printing, share_plus, image_picker.

## Что реализовал я
- Экзамен ГАИ: 20 вопросов / 20 мин / до 2 ошибок, билеты 1–40, марафон 800, темы, работа над ошибками, карта ошибок
- ИИ-инструктор: Ollama Cloud + локальный LM Studio/Ollama, анализ ошибок по темам, подбор цели, детские объяснения с локальным fallback без сети
- Геймификация: streak, монеты, магазин из 12 тем, достижения, PDF-отчёт, бэкап/импорт JSON
- Безопасность: токен только в EncryptedSharedPreferences, HTTPS по умолчанию + `network_security_config` (cleartext лишь для localhost/10.0.2.2), release-подпись через `key.properties` (не в репо), `applicationId com.drivemind.pdd`
- Детский режим: упрощённые формулировки, озвучка, крупные кнопки

## Архитектура
```
lib/app.dart            # роуты, темы, DynamicColor
lib/core/llm/           # LlmService: chat, fetchModels, analyzeErrors, explainForKids
lib/core/storage/       # Hive box 'drivemind' + префы, streak/квесты
lib/core/notifications/ # локальные напоминания 19:00
lib/core/theme/         # 12 пресетов, градиенты
lib/features/exam|tickets|marathon|trainer|themes|mistakes|stats|instructor|kids|...
lib/data/models/        # Question, Profile
```

## Запуск
```bash
flutter pub get
flutter run
# релиз: скопируй android/key.properties.example -> android/key.properties, заполни, затем
flutter build appbundle --release
```

## Датасет
В этой папке — только сэмпл. Полные `questions.json` (800), `signs.json`, картинки лежат локально у автора и в репо не пушатся. Детали — `assets/data/README_DATASET.md`, права — `NOTICE.md`.

## Дисклеймер
Неофициальный учебный проект, не ГИБДД/МВД. ИИ может ошибаться. Часть учебных формулировок исторически производна от github.com/etspring/pdd_russia — см. `NOTICE.md`.
