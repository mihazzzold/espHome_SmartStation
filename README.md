# espHome SmartStation (ESP32-C3)

Прошивка для создания умной колонки (Voice Assistant) на базе ESP32-C3 SuperMini, ЦАП PCM5102A и микрофона INMP441.

## Особенности
- Поддержка Home Assistant Voice Assistant (STT/TTS).
- Высококачественный вывод звука через I2S ЦАП PCM5102A.
- Захват голоса через I2S микрофон INMP441.
- Управление активацией через физическую кнопку.
- Индикация статуса встроенным светодиодом.

## Схема подключения

### PCM5102A (I2S Output)
- **VCC** -> 3.3V / 5V
- **GND** -> GND
- **BCK** (BCLK) -> GPIO2
- **DIN** (DOUT) -> GPIO1
- **LCK** (LRCK/WS) -> GPIO3

### INMP441 (I2S Input)
- **VDD** -> 3.3V
- **GND** -> GND
- **L/R** -> GND (Left channel)
- **SD** (SDOUT) -> GPIO6
- **WS** (LRCK) -> GPIO3 (Общий с PCM5102A)
- **SCK** (BCLK) -> GPIO2 (Общий с PCM5102A)

### Дополнительно
- **Кнопка (Активация)** -> GPIO9 (Встроенная кнопка Boot)
- **LED (Статус)** -> GPIO8 (Встроенный LED)

## Настройка в Home Assistant
После прошивки устройство появится в Home Assistant. Для работы голосового ассистента:
1. Зайдите в настройки устройства ESPHome.
2. Убедитесь, что компонент "Voice Assistant" активен.
3. В настройках HA перейдите в "Голосовые помощники" (Assist) и настройте пайплайн.
