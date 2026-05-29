# 🎙️ SmartStation — пайка и Home Assistant

Голосовой **сателлит** Assist: **ESP32-C3** или **ESP32-C6** SuperMini + INMP441 + MAX98357A. Устройство **не понимает** команды само — только слушает, шлёт звук в HA и играет ответ.

| Плата | Профиль flasher | Канал OTA на сервере |
|-------|-----------------|----------------------|
| ESP32-C3 SuperMini | `esp32c3-supermini` | `mihazzzold.espHome-SmartStation.esp32c3` |
| ESP32-C6 SuperMini | `esp32c6-supermini` | `mihazzzold.espHome-SmartStation.esp32c6` |

Пины I2S и кнопки **одинаковые** на обеих платах (см. `firmwares/boards/esp32c3-supermini.yaml` и `esp32c6-supermini.yaml`, секция SmartStation).

---

## 📋 Оглавление

1. [🔌 Пайка и питание](#readme-wiring)
2. [📦 Прошивка](#readme-flash)
3. [🏠 Home Assistant (кратко)](#readme-ha)
4. [🗣️ Wake-word: два режима](#readme-wake)
5. [✅ Проверка](#readme-test)
6. [🐛 Частые проблемы](#readme-troubleshoot)

> 📘 **Подробная настройка HA (Assist, сущности, OTA, автоматизации):** [`HOME_ASSISTANT.md`](HOME_ASSISTANT.md)

---

<a id="readme-wiring"></a>
## 🔌 Пайка и питание

> ⚠️ **ESP32-C6:** GPIO8 и GPIO9 — **strapping**. Не вешайте сильные внешние подтяжки; кнопку — только GPIO9 + GND.  
> **ESP32-C3:** кнопка BOOT на GPIO9, LED на GPIO8 (как на SuperMini).

### Что понадобится

| Модуль | Роль |
|--------|------|
| ESP32-C3 / C6 SuperMini | Wi‑Fi, Assist, LED на GPIO8 |
| INMP441 | Микрофон I2S |
| MAX98357A | Усилитель I2S → динамик 4–8 Ω |
| Кнопка (нормально разомкнутая) | Активация без wake-word |
| Провода, макетка/плата, **общая земля** | |

### Питание

| Узел | Напряжение | Комментарий |
|------|------------|-------------|
| ESP32-C3 / C6 | 5 V по USB **или** 3.3 V на 3V3 | Прошивка и Wi‑Fi |
| INMP441 | **3.3 V** | Не подавайте 5 V на MEMS |
| MAX98357A | **5 V** на VIN (рекомендуется) | Громче и стабильнее TTS; 3.3 V — тише |
| Динамик | 4–8 Ω | Между MAX98357A и GND |

**Земля:** GND ESP32, INMP441 и MAX98357A — **одна общая точка**. Линии I2S — короткие (до ~10 см).

### Таблица пайки (профили `esp32c3-supermini` / `esp32c6-supermini`)

| Сигнал I2S | ESP32 (C3/C6) | INMP441 | MAX98357A |
|------------|----------|---------|-----------|
| BCLK (SCK) | **GPIO2** | SCK | BCLK |
| LRCLK (WS) | **GPIO3** | WS | LRC |
| Данные **от мика** | **GPIO6** ← | SD | — |
| Данные **на усилитель** | **GPIO1** → | — | DIN |
| Питание | 3V3 | VDD | — |
| Питание усилителя | — | — | VIN → **5V** |
| Земля | GND | GND | GND |

| Прочее | ESP32 (C3/C6) | Подключение |
|--------|----------|-------------|
| Кнопка активации | **GPIO9** | Один вывод на GPIO9, второй на **GND** |
| Статус LED | **GPIO8** | Уже на плате SuperMini |

```
        ┌─────────────┐
  3V3 ──┤ INMP441     │
  GND ──┤  SCK ───────┼── GPIO2 (BCLK) ───┬── MAX98357 BCLK
  GPIO6 ├─ SD         │                   │
  GPIO3 ├─ WS ────────┼───────────────────┼── MAX98357 LRC
        └─────────────┘                   │
                              GPIO1 ──────┴── MAX98357 DIN
                              5V  ─────────── MAX98357 VIN
                              GND ─────────── общая земля
```

> 💡 **Совет:** L/R на MAX98357A — по даташиту (часто GND = моно). SD на MAX98357A — в **HIGH** (всегда включён), если есть пин SD.

---

<a id="readme-flash"></a>
## 📦 Прошивка

1. В `firmwares/secrets.yaml` — Wi‑Fi, `api_encryption_key`, `ota_password`.
2. Из корня репозитория:

```powershell
python scripts/apply_ci_overrides.py
```

### Завод / розница (вариант A — один OTA-бинарник на всех)

Без STA Wi‑Fi из `secrets`, уникальный hostname по MAC (`esphome-smartstation-…`), AP **`station-setup`** + Improv:

```powershell
py -3.13 scripts/flasher.py --local `
  -f firmwares-external/mihazzzold.espHome-SmartStation/espHome_SmartStation.yaml.j2 `
  --board-profile esp32c6-supermini `
  --factory-build `
  -a run --port COM5 -y
```

Эквивалент: `$env:FLASHER_FACTORY_BUILD="1"` (в CI OTA для SmartStation включается автоматически).

> Не задавайте `FLASHER_SERIAL_NUMBER` при заводской прошивке — иначе только имя файла YAML изменится, а не логика образа.

### Разработка / своё устройство (уникальный serial)

В `firmwares/secrets.yaml` — Wi‑Fi, `api_encryption_key`, `ota_password`. Прошивка с фиксированным serial (как на коробке / в HA):

```powershell
$env:FLASHER_SERIAL_NUMBER = "esp-1779448484-109"
py -3.13 scripts/flasher.py --local `
  -f firmwares-external/mihazzzold.espHome-SmartStation/espHome_SmartStation.yaml.j2 `
  --board-profile esp32c6-supermini `
  -a run --port COM19 -y
```

3. Первый запуск: при заводском образе — AP **`station-setup`**; при dev — `station-<суффикс>-setup` и captive portal для Wi‑Fi.

---

<a id="readme-ha"></a>
## 🏠 Home Assistant (кратко)

Нужен **Home Assistant 2023.5+** (лучше 2024/2025). Полный пошаговый гайд: **[`HOME_ASSISTANT.md`](HOME_ASSISTANT.md)**.

1. **ESPHome** + устройство после прошивки (`api_encryption_key` из secrets).
2. Дополнения **Whisper** + **Piper** (и **openWakeWord**, если wake в HA).
3. **Голосовой ассистент**: STT → Intent (Home Assistant) → TTS, язык **Русский**.
4. **Сателлит** = карточка **SmartStation · …** в настройках ассистента.
5. **SETUP:** язык → **Завершить настройку** на карточке устройства.
6. В логах: `Voice Assistant client connected to Home Assistant`.

---

<a id="readme-wake"></a>
## 🗣️ Wake-word: два режима

В HA у сущности **«Движок wake-word»**:

| Режим в HA | Как работает | Что нужно в HA |
|------------|--------------|----------------|
| **На устройстве** | Фраза ловится на ESP (micro_wake_word: okay nabu, hey jarvis) | Модели можно включать в сущностях microWakeWord |
| **В Home Assistant** | Поток звука на сервер, wake-word там (openWakeWord и т.п.) | Настроенный wake-word в пайплайне / Wyoming openWakeWord |

**Кнопка на GPIO9** — всегда: короткое нажатие = начать слушать / оборвать сессию (без wake-word).

> 💡 Фраза «Хей, Хоум» в прошивке **не зашита** — нужна своя модель microWakeWord или wake-word в HA. Пока используйте встроенные модели или кнопку.

---

<a id="readme-test"></a>
## ✅ Проверка

1. **LED тускло** после загрузки и подключения к HA — режим ожидания (фаза 1).
2. Скажите wake-word (или нажмите кнопку) → LED **мигает** — слушает (фаза 3).
3. Команда: *«Включи свет в …»* → пауза → ответ из динамика (фазы 4–5).
4. В HA: кнопки **«Тест динамика»** / **«Тест микрофона»** — диагностика без умного дома.

---

<a id="readme-troubleshoot"></a>
## 🐛 Частые проблемы

| Симптом | Что проверить |
|---------|----------------|
| Нет связи с HA | Wi‑Fi, ключ API, версия HA ≥ 2023.5 |
| Молчит после команды | TTS в ассистенте, громкость MAX98357A, питание 5 V |
| Не слышит | Пайка GPIO6 ← SD INMP441, 3.3 V на микрофон |
| Треск / эхо | Общая GND, короткие I2S, питание усилителя отдельно от USB-хаоса |
| Wake не срабатывает | Режим «Движок wake-word», громкость речи, попробуйте **кнопку** |
| Предупреждения GPIO8/9 | Норма для C6; не меняйте подтяжки на strapping |

---

📚 Канон прошивки: `firmwares/ci-overrides/mihazzzold.espHome-SmartStation/`  
🌐 Доки ESPHome: [Voice Assistant](https://esphome.io/components/voice_assistant/)
