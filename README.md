# Klipper Log Tool

Parses the log and only returns important information for debugging

## Upload the last start to a pastebin

```bash
bash <(curl -sSL https://raw.githubusercontent.com/reemo3dp/klipper_log_tool/main/klipper_log_tool.sh) --upload
```

## Upload all starts minus the noise to a pastebin

```bash
bash <(curl -sSL https://raw.githubusercontent.com/reemo3dp/klipper_log_tool/main/klipper_log_tool.sh) --upload --all-starts
```

## Upload a klippy.log other than the default (~/printer_data/logs/klippy.log)

```bash
bash <(curl -sSL https://raw.githubusercontent.com/reemo3dp/klipper_log_tool/main/klipper_log_tool.sh) --upload --all-starts /home/pi/klippy.log
```

## Only de-noise the input

```bash
bash <(curl -sSL https://raw.githubusercontent.com/reemo3dp/klipper_log_tool/main/klipper_log_tool.sh) --all-starts /home/pi/klippy.log
```
