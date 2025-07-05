# Sexy aaa lib (ESP)

# esb lib for blink.lol

---

## Features

* **Boxes** around players
* **Name** (or DisplayName)
* **Distance** from camera
* **Health Bar** showing remaining HP
* **Inventory** list (all or closest to cursor)
* **Configurable** defaults and overrides

---

## Settings Reference

| Section       | Option           | Type      | Default                     | Description                           |
| ------------- | ---------------- | --------- | --------------------------- | ------------------------------------- |
| **Box**       | `Enabled`        | `boolean` | `true`                      | Turn box drawing on/off               |
|               | `Color`          | `Color3`  | `Color3.fromRGB(128, 0, 0)` | Box outline color                     |
|               | `Thickness`      | `number`  | `1`                         | Line thickness                        |
|               | `Filled`         | `boolean` | `false`                     | Fill the box interior                 |
| **Name**      | `Enabled`        | `boolean` | `true`                      | Show player name                      |
|               | `UseDisplayName` | `boolean` | `true`                      | Use `.DisplayName` instead of `.Name` |
|               | `Color`          | `Color3`  | `Color3.new(1,1,1)`         | Text color                            |
|               | `Size`           | `number`  | `14`                        | Font size                             |
| **Distance**  | `Enabled`        | `boolean` | `true`                      | Show distance text                    |
| **HealthBar** | `Enabled`        | `boolean` | `true`                      | Show health bar                       |
|               | `Width`          | `number`  | `2`                         | Health bar line thickness             |
| **Inventory** | `Enabled`        | `boolean` | `true`                      | Show inventory list                   |
|               | `Mode`           | `1 or 2`  | `2`                         | `1 = All`, `2 = Closest to cursor`    |
|               | `Color`          | `Color3`  | `Color3.new(1,1,1)`         | Inventory text color                  |
|               | `Size`           | `number`  | `14`                        | Font size for inventory               |

> You can override any of these by passing a table to `ESPLib.new(...)`.

---

## Example Usage

```lua
local raw = game:HttpGet("https://raw.githubusercontent.com/user/roblox-esp-lib/main/ESPLibrary.lua")
local ESPLib = loadstring(raw)()

-- Default ESP
local defaultESP = ESPLib.new()
defaultESP:Start()

-- Customized ESP
local customESP = ESPLib.new({
  Box  = { Color = Color3.new(1,0,0), Thickness = 3 },
  Name = { Size = 18, Color = Color3.new(1,1,0) },
  Inventory = { Mode = 1 }
})
customESP:Start()
```

---

## License

MIT © zmqf & pd
