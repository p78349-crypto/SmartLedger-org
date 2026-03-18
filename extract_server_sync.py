import os
import re

file_path = 'lib/screens/server_sync_settings_screen.dart'
logic_path = 'lib/screens/server_sync_settings_screen_logic.dart'

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

# Logic block names
logic_methods = [
    r'Future<void>\s+_showRecoveryKeyRestoreDialog',
    r'Future<void>\s+_showServerConfigDialog',
    r'Future<String\?>\s+_resolveSyncAccountName',
    r'Future<void>\s+_runManualSync'
]

logic_code = ""
for p in logic_methods:
    idx = find_line_idx(p)
    if idx != -1:
        block = extract_block(idx)
        logic_code += block + "\n"

# Rewrite logic
with open(logic_path, 'w', encoding='utf-8') as f:
    f.write("part of 'server_sync_settings_screen.dart';\n\n")
    f.write("extension ServerSyncSettingsLogic on _ServerSyncSettingsScreenState {\n")
    f.write(logic_code)
    f.write("}\n")

# Main screen edits
orig_content = "".join(lines)

for p in logic_methods:
    idx = find_line_idx(p)
    if idx != -1:
        block = extract_block(idx)
        orig_content = orig_content.replace(block, "")

# Inject part statements after last import
orig_content = orig_content.replace("import '../utils/password_key_backup_models.dart';", "import '../utils/password_key_backup_models.dart';\n\npart 'server_sync_settings_screen_logic.dart';")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(orig_content)

print("Extraction complete.")
