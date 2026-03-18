import os
import re

file_path = 'lib/screens/asset_security_settings_screen.dart'
logic_path = 'lib/screens/asset_security_settings_screen_logic.dart'
ui_path = 'lib/screens/asset_security_settings_screen_ui.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

def extract_block(start_line_idx):
    if start_line_idx == -1: return ""
    brace_count = 0
    extracted = []
    started = False
    
    for i in range(start_line_idx, len(lines)):
        line = lines[i]
        extracted.append(line)
        if '{' in line:
            brace_count += line.count('{')
            started = True
        if '}' in line:
            brace_count -= line.count('}')
        
        if started and brace_count == 0:
            return "".join(extracted)
    return ""

def find_line_idx(pattern):
    for i, line in enumerate(lines):
        if re.search(pattern, line):
            return i
    return -1

# 1. Logic block names
logic_methods = [
    r'Future<void>\s+_initialize',
    r'Future<void>\s+_checkBiometricAvailability',
    r'Future<void>\s+_loadCurrentSettings',
    r'void\s+_applyMode',
    r'Future<void>\s+_togglePin',
    r'Future<void>\s+_toggleBiometric',
    r'Future<void>\s+_togglePassword',
    r'Future<void>\s+_saveSettings',
    r'Future<void>\s+_setupPin',
    r'Future<void>\s+_setupPassword'
]

logic_code = ""
for p in logic_methods:
    idx = find_line_idx(p)
    if idx != -1:
        block = extract_block(idx)
        logic_code += block + "\n"

# 2. UI block names
ui_methods = [
    r'Widget\s+_buildModeCard',
    r'Widget\s+_buildSettingTile'
]

ui_code = ""
for p in ui_methods:
    idx = find_line_idx(p)
    if idx != -1:
        block = extract_block(idx)
        ui_code += block + "\n"

# 3. Write logic file
with open(logic_path, 'w', encoding='utf-8') as f:
    f.write("part of 'asset_security_settings_screen.dart';\n\n")
    f.write("extension AssetSecuritySettingsLogic on _AssetSecuritySettingsScreenState {\n")
    # Replace snackbar and routing to inject context.mounted
    modified_logic = logic_code
    modified_logic = modified_logic.replace("Navigator.pop(context", "if (!context.mounted) return;\n      Navigator.pop(context")
    modified_logic = modified_logic.replace("ScaffoldMessenger.of(context)", "if (!context.mounted) return;\n      ScaffoldMessenger.of(context)")
    f.write(modified_logic)
    f.write("}\n")

# 4. Write UI file
with open(ui_path, 'w', encoding='utf-8') as f:
    f.write("part of 'asset_security_settings_screen.dart';\n\n")
    f.write("extension AssetSecuritySettingsUI on _AssetSecuritySettingsScreenState {\n")
    f.write(ui_code)
    f.write("}\n")

# 5. Remove extracted from main and insert parts
orig_content = "".join(lines)

# Remove logic blocks
for p in logic_methods:
    idx = find_line_idx(p)
    if idx != -1:
        block = extract_block(idx)
        orig_content = orig_content.replace(block, "")

# Remove UI blocks
for p in ui_methods:
    idx = find_line_idx(p)
    if idx != -1:
        block = extract_block(idx)
        orig_content = orig_content.replace(block, "")

# Inject parts
parts = "import 'package:local_auth/local_auth.dart';\n\npart 'asset_security_settings_screen_logic.dart';\npart 'asset_security_settings_screen_ui.dart';\n"
orig_content = orig_content.replace("import 'package:local_auth/local_auth.dart';", parts)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(orig_content)

print("Extraction complete.")
