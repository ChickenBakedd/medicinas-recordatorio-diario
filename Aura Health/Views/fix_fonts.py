import os
import re

directory = '.'

# Matches .font(.system(.STYLE, design: .DESIGN, weight: .WEIGHT))
pattern1 = re.compile(r'\.font\(\.system\(\.(?P<style>[a-zA-Z0-9]+),\s*design:\s*\.(?P<design>[a-zA-Z0-9]+),\s*weight:\s*\.(?P<weight>[a-zA-Z0-9]+)\)\)')

# Matches .font(.system(.STYLE, weight: .WEIGHT, design: .DESIGN))
pattern2 = re.compile(r'\.font\(\.system\(\.(?P<style>[a-zA-Z0-9]+),\s*weight:\s*\.(?P<weight>[a-zA-Z0-9]+),\s*design:\s*\.(?P<design>[a-zA-Z0-9]+)\)\)')

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.swift'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()
            
            new_content = pattern1.sub(r'.font(.system(.\g<style>, design: .\g<design>).weight(.\g<weight>))', content)
            new_content = pattern2.sub(r'.font(.system(.\g<style>, design: .\g<design>).weight(.\g<weight>))', new_content)
            
            if new_content != content:
                print(f"Updated {filepath}")
                with open(filepath, 'w') as f:
                    f.write(new_content)
