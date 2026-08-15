import os
import json

colors = {
    "backgroundTop": {"light": [0.98, 0.96, 0.93, 1.0], "dark": [0.12, 0.12, 0.14, 1.0]},
    "backgroundBottom": {"light": [0.93, 0.89, 0.84, 1.0], "dark": [0.08, 0.08, 0.10, 1.0]},
    "doseCard": {"light": [0.96, 0.97, 1.0, 1.0], "dark": [0.18, 0.18, 0.22, 1.0]},
    "appointmentsCard": {"light": [1.0, 0.96, 0.93, 1.0], "dark": [0.20, 0.18, 0.16, 1.0]},
    "barFill": {"light": [0.99, 0.97, 0.94, 1.0], "dark": [0.15, 0.15, 0.18, 1.0]},
    "trackGray": {"light": [0.82, 0.79, 0.75, 1.0], "dark": [0.35, 0.35, 0.40, 1.0]},
    "chipFill": {"light": [1.0, 1.0, 1.0, 0.65], "dark": [0.25, 0.25, 0.25, 0.65]},
    "softShadow": {"light": [0.0, 0.0, 0.0, 0.07], "dark": [0.0, 0.0, 0.0, 0.3]},
    "textPrimary": {"light": [0.22, 0.20, 0.18, 1.0], "dark": [0.95, 0.95, 0.95, 1.0]},
    "textSecondary": {"light": [0.42, 0.38, 0.34, 1.0], "dark": [0.75, 0.75, 0.75, 1.0]},
    "textMuted": {"light": [0.55, 0.50, 0.46, 1.0], "dark": [0.60, 0.60, 0.60, 1.0]}
}

assets_dir = "/Users/miguelito/Desktop/Aura Health/Aura Health/Assets.xcassets"

for name, modes in colors.items():
    color_dir = os.path.join(assets_dir, f"{name}.colorset")
    os.makedirs(color_dir, exist_ok=True)
    
    contents = {
      "info" : {
        "author" : "xcode",
        "version" : 1
      },
      "colors" : [
        {
          "idiom" : "universal",
          "color" : {
            "color-space" : "srgb",
            "components" : {
              "red" : str(modes["light"][0]),
              "green" : str(modes["light"][1]),
              "blue" : str(modes["light"][2]),
              "alpha" : str(modes["light"][3])
            }
          }
        },
        {
          "idiom" : "universal",
          "appearances" : [
            {
              "appearance" : "luminosity",
              "value" : "dark"
            }
          ],
          "color" : {
            "color-space" : "srgb",
            "components" : {
              "red" : str(modes["dark"][0]),
              "green" : str(modes["dark"][1]),
              "blue" : str(modes["dark"][2]),
              "alpha" : str(modes["dark"][3])
            }
          }
        }
      ]
    }
    
    with open(os.path.join(color_dir, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)

print("Colors generated successfully.")
