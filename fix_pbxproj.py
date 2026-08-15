import os

filepath = "/Users/miguelito/Desktop/Aura Health/Aura Health.xcodeproj/project.pbxproj"
with open(filepath, 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if "ENABLE_APP_SANDBOX = YES;" in line:
        continue
    if "ENABLE_USER_SELECTED_FILES = readonly;" in line:
        continue
    new_lines.append(line)

with open(filepath, 'w') as f:
    f.writelines(new_lines)
print("Removed macOS sandbox entitlements from project.pbxproj")
