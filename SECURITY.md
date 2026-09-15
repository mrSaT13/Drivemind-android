# Безопасность — что проверено 15.09.2026

## Утечки: ЧИСТО
- Нет хардкода токенов/ключей. `grep` по коду находит только поле `token`
  в `lib/core/llm/llm_service.dart` + UI `tokenCtrl` (obscureText) +
  `Authorization: Bearer`. Токен вводит пользователь.
- Нет `*.env`, `*.jks`, `*.keystore`, `google-services.json`, private keys.
- `android/local.properties` (пути `D:\android-sdk-full`, `D:\flutter`)
  в публикацию НЕ входит (есть в .gitignore, в папке отсутствует — проверено).
- Нет абсолютных путей `D:\`, `C:\Users` в `lib/` (проверено).
- Нет `print(`/`debugPrint`/`TODO`/`FIXME` в `lib/`.

## Риски (не утечки, но исправить до продакшна)
1. **Токен в plaintext:** `SharedPreferences` = XML без шифрования.
   → Мигрируй на `flutter_secure_storage` для `llm_config.token`.
2. **`usesCleartextTraffic="true"` + `requestLegacyExternalStorage="true"`**
   в AndroidManifest — нужно только для `http://localhost:1234` / `10.0.2.2`
   (LM Studio). Для Play Store: `false` + `network_security_config.xml`
   с разрешением только для localhost/10.0.2.2.
3. **`REQUEST_INSTALL_PACKAGES`** (тянет share_plus) — триггерит Play Protect.
   Если не обновляешь APK из приложения — убери через `tools:node="remove"`.
4. **`StorageService.import()` без try/catch:** битый JSON = краш.
   Оберни в try/catch + валидацию схемы.
5. **Backup через Share:** `drivemind_backup.json` / `StorageService.export()`
   шарится в мессенджеры открытым текстом — предупреди пользователя.
6. **Подпись релиза:** сейчас `signingConfig debug`. Для Play нужен свой
   keystore (НЕ коммитить!) + `signingConfigs.release`.
7. **applicationId `com.example.drivemind_mobile`** — замени на свой
   (`com.drivemind.pdd` и т.п.), иначе не примут в Play.
8. **google_fonts** грузит шрифты из сети — для офлайн/приватности
   положи Manrope/Roboto в assets.

## Android-разрешения (все по делу)
INTERNET + ACCESS_NETWORK_STATE (LLM), CAMERA (аватар),
POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM /
RECEIVE_BOOT_COMPLETED / WAKE_LOCK (напоминания 19:00).
На Android 14+ проверять `canScheduleExactAlarms()`.
