import os
import glob

def add_theme_mode(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    if '.applyThemeMode()' in content:
        return
        
    # We want to add it right before the closing brace of the main view body if possible,
    # or just look for the typical pattern where sheets are added
    # A safer way is to just do a simple string replace for known files:
    
    replacements = {
        "ProGlassAddMenuSheet.swift": (".sheet(isPresented: $showHealthVitals) {\n            ProGlassHealthVitalsView(store: store)\n                .environment(\\.appTheme, theme)\n        }\n    }", ".sheet(isPresented: $showHealthVitals) {\n            ProGlassHealthVitalsView(store: store)\n                .environment(\\.appTheme, theme)\n        }\n        .applyThemeMode()\n    }"),
        "AddMenuSheet.swift": (".sheet(isPresented: $showHealthVitals) {\n            HealthVitalsView(store: store)\n                .environment(\\.appTheme, theme)\n        }\n    }", ".sheet(isPresented: $showHealthVitals) {\n            HealthVitalsView(store: store)\n                .environment(\\.appTheme, theme)\n        }\n        .applyThemeMode()\n    }"),
        "ProGlassAddAppointmentView.swift": (".onAppear { vm.loadExistingIfNeeded() }\n    }", ".onAppear { vm.loadExistingIfNeeded() }\n        .applyThemeMode()\n    }"),
        "AddAppointmentView.swift": (".onAppear { vm.loadExistingIfNeeded() }\n    }", ".onAppear { vm.loadExistingIfNeeded() }\n        .applyThemeMode()\n    }"),
    }
    
    filename = os.path.basename(filepath)
    if filename in replacements:
        old, new = replacements[filename]
        if old in content:
            content = content.replace(old, new)
            with open(filepath, 'w') as f:
                f.write(content)
            print(f"Fixed {filename}")

for root, _, files in os.walk('Aura Health/Views'):
    for file in files:
        if file.endswith('.swift'):
            add_theme_mode(os.path.join(root, file))

