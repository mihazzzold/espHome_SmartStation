# 🎙️ espHome SmartStation (ESP32-C3 / ESP32-C6)

[![Version](https://img.shields.io/badge/version-0.2.0.2-blue.svg)](../../../CHANGELOG.md)

Голосовой сателлит Home Assistant **Assist**: **INMP441** + **MAX98357A** на **ESP32-C3** или **ESP32-C6** SuperMini.

## 🧩 Матрица поддержки плат

| Плата | Wi-Fi (ESPHome) | Zigbee (ESP-IDF) | Причина ограничения |
| --- | --- | --- | --- |
| **ESP32** (classic, WROOM-32) | ❌ | ❌ | `_includes/runtime.yaml.j2` жёстко прописывает `variant: esp32c6` (требует доработки шаблона) |
| **ESP32-C3** SuperMini | ✅ | ❌ | нет 802.15.4 |
| **ESP32-C6** SuperMini | ✅ (рекомендуется) | ❌ | Assist требует Wi-Fi, в Zigbee нет смысла |
| **ESP32-H2** | ❌ | ❌ | нет Wi-Fi 802.11 + нет смысла в Zigbee для voice |
| **ESP8266** NodeMCU | ❌ | ❌ | не хватает RAM/Flash для Assist pipeline |

| Плата | Профиль `flasher` | OTA на сервере |
|-------|-------------------|----------------|
| ESP32-C3 SuperMini | `esp32c3-supermini` | `mihazzzold.espHome-SmartStation.esp32c3` |
| ESP32-C6 SuperMini | `esp32c6-supermini` | `mihazzzold.espHome-SmartStation.esp32c6` |

Пины I2S и кнопки **одинаковые** на C3 и C6 (см. `firmwares/boards/*-supermini.yaml`, секция SmartStation).

## ✨ Особенности

- 🤖 **Voice Assistant** + **micro_wake_word** (okay nabu, hey jarvis) или wake-word в HA (openWakeWord)
- 🔈 **I2S выход**: MAX98357A → динамик 4–8 Ω
- 🎤 **I2S вход**: INMP441
- 🔘 **Push-to-talk**: GPIO9 (BOOT)
- 💡 **LED фаз**: GPIO8 (PWM)
- 🔄 **OTA**: `update.http_request` + manifest на ota-s3 (отдельный bin для C3 и C6)
- 🏭 **Заводской режим**: `--factory-build` — `esphome-smartstation` + MAC, без STA Wi‑Fi из secrets

## 📦 Прошивка

Из корня **esphomeFlasher**:

```powershell
python scripts/apply_ci_overrides.py
```

| Режим | Команда |
|-------|---------|
| **Завод / OTA для покупателей** | `--factory-build` (или `FLASHER_FACTORY_BUILD=1`) |
| **Своя станция** | `$env:FLASHER_SERIAL_NUMBER="esp-…"` + обычный `run` |

```powershell
# ESP32-C6, завод:
py -3.13 scripts/flasher.py --local `
  -f firmwares-external/mihazzzold.espHome-SmartStation/espHome_SmartStation.yaml.j2 `
  --board-profile esp32c6-supermini --factory-build -a run --port COM5 -y
```

Подробнее: [`SETUP.md`](SETUP.md).

## 🏠 Home Assistant

| Документ | Содержание |
|----------|------------|
| **[`HOME_ASSISTANT.md`](HOME_ASSISTANT.md)** | Wyoming, Assist, сателлит, wake-word, OTA, troubleshooting |
| [`SETUP.md`](SETUP.md) | Пайка, питание, прошивка |

Краткий порядок: **Whisper + Piper** (дополнения) → Wyoming → ассистент **main** → ESPHome → SETUP на устройстве → сателлит → тесты динамика/микрофона.

## 🔄 OTA

- **C3:** `…/mihazzzold.espHome-SmartStation.esp32c3/manifest.json`
- **C6:** `…/mihazzzold.espHome-SmartStation.esp32c6/manifest.json`

CI собирает заводской образ (`FLASHER_FACTORY_BUILD` + `FLASHER_OTA_GENERIC_BUILD`).

---

📚 Это **канон в git**; копия после `apply_ci_overrides.py` → `firmwares-external/mihazzzold.espHome-SmartStation/`.
