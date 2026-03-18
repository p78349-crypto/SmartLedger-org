import os
import re

file_path = 'lib/screens/phase2_demo_screen.dart'
logic_path = 'lib/screens/phase2_demo_screen_logic.dart'
ui_path = 'lib/screens/phase2_demo_screen_ui.dart'

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
    r'Future<void>\s+_demoAction',
    r'Future<void>\s+_logModeChange',
    r'Future<void>\s+_runIntegrationTest'
]

logic_code = ""
for p in logic_methods:
    idx = find_line_idx(p)
    if idx != -1:
        block = extract_block(idx)
        logic_code += block + "\n"

# UI block names
ui_methods = [
    r'Widget\s+_buildSimpleModeDemo',
    r'Widget\s+_buildKPIDashboardDemo',
    r'Widget\s+_buildPermissionDemo',
    r'Widget\s+_buildIntegrationDemo',
    r'Widget\s+_buildPermissionTestButton',
    r'Widget\s+_buildIntegrationTestTile'
]

ui_code = ""
for p in ui_methods:
    idx = find_line_idx(p)
    if idx != -1:
        block = extract_block(idx)
        ui_code += block + "\n"

# Rewrite logic
with open(logic_path, 'w', encoding='utf-8') as f:
    f.write("part of 'phase2_demo_screen.dart';\n\n")
    f.write("extension Phase2DemoLogic on _Phase2DemoScreenState {\n")
    # Replace snackbar to inject context mounted
    modified_logic = logic_code
    modified_logic = modified_logic.replace("ScaffoldMessenger.of(context)", "if (!context.mounted) return;\n    ScaffoldMessenger.of(context)")
    f.write(modified_logic)
    f.write("}\n")

# Rewrite UI
with open(ui_path, 'w', encoding='utf-8') as f:
    f.write("part of 'phase2_demo_screen.dart';\n\n")
    f.write("extension Phase2DemoUI on _Phase2DemoScreenState {\n")
    f.write(ui_code)
    f.write("}\n")

# Main screen edits
orig_content = "".join(lines)

for p in logic_methods + ui_methods:
    idx = find_line_idx(p)
    if idx != -1:
        block = extract_block(idx)
        orig_content = orig_content.replace(block, "")

# Inject part statements after last import
orig_content = orig_content.replace("import 'package:smart_ledger/services/audit_log_service.dart';", "import 'package:smart_ledger/services/audit_log_service.dart';\n\npart 'phase2_demo_screen_logic.dart';\npart 'phase2_demo_screen_ui.dart';")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(orig_content)

print("Extraction complete.")
