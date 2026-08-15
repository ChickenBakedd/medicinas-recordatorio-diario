import os

filepath = "/Users/miguelito/Desktop/Aura Health/Aura Health.xcodeproj/project.pbxproj"
with open(filepath, 'r') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    new_lines.append(line)
    if "GENERATE_INFOPLIST_FILE = YES;" in line:
        new_lines.append('\t\t\t\tINFOPLIST_KEY_NSCameraUsageDescription = "Aura Health needs camera access to scan medication boxes.";\n')

with open(filepath, 'w') as f:
    f.writelines(new_lines)
print("Added camera permission to pbxproj")
