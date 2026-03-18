import os
import re

file_path = 'lib/screens/micro_savings_nudge_screen.dart'
logic_path = 'lib/screens/micro_savings_nudge_screen_logic.dart'
ui_path = 'lib/screens/micro_savings_nudge_screen_ui.dart'

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

logic_methods = [
    r'Future<void>\s+_load\(\)',
    r'Future<void>\s+_onBatchSave\(\)'
]

ui_methods = [
    r'Widget\s+_quickEntryCard',
    r'Widget\s+_targetPresetChip',
    r'Widget\s+_metric',
    r'Widget\s+build\(BuildContext\s+context\)'
]

logic_code = ""
for p in logic_methods:
    idx = find_line_idx(p)
    if idx != -1:
        logic_code += extract_block(idx) + "\n"

ui_code = ""
for p in ui_methods:
    idx = find_line_idx(p)
    if idx != -1:
        block = extract_block(idx)
        if "Widget build(BuildContext context)" in block:
            block = block.replace("Widget build(BuildContext context)", "Widget _buildContent(BuildContext context)")
        ui_code += block + "\n"

with open(logic_path, 'w', encoding='utf-8') as f:
    f.write("part of 'micro_savings_nudge_screen.dart';\n\n")
    f.write("extension MicroSavingsNudgeLogic on _MicroSavingsNudgeScreenState {\n")
    modified_logic = logic_code.replace("ScaffoldMessenger.of(context)", "if (!context.mounted) return;\n    ScaffoldMessenger.of(context)")
    modified_logic = modified_logic.replace("Navigator.pop(context)", "if (!context.mounted) return;\n    Navigator.pop(context)")
    f.write(modified_logic)
    f.write("}\n")

with open(ui_path, 'w', encoding='utf-8') as f:
    f.write("part of 'micro_savings_nudge_screen.dart';\n\n")
    f.write("extension MicroSavingsNudgeUI on _MicroSavingsNudgeScreenState {\n")
    f.write(ui_code)
    f.write("}\n")

orig_content = "".join(lines)

for p in logic_methods + ui_methods:
    idx = find_line_idx(p)
    if idx != -1:
        block = extract_block(idx)
        if "Widget build(BuildContext context)" in block:
            orig_content = orig_content.replace(block, "  @override\n  Widget build(BuildContext context) => _buildContent(context);")
        else:
            orig_content = orig_content.replace(block, "")

idx_import = -1
for i, line in enumerate(lines):
    if line.startswith('import '):
        idx_import = i

if idx_import != -1:
    lines_split = orig_content.split('\n')
    lines_split.insert(idx_import + 1, "\npart 'micro_savings_nudge_screen_logic.dart';\npart 'micro_savings_nudge_screen_ui.dart';\n")
    orig_content = '\n'.join(lines_split)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(orig_content)

print("Extraction complete.")
