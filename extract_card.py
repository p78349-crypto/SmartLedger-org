import os
import re

file_path = 'lib/screens/card_discount_stats_screen.dart'
logic_path = 'lib/screens/card_discount_stats_screen_logic.dart'
ui_path = 'lib/screens/card_discount_stats_screen_ui.dart'

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
    r'Future<void>\s+_loadPointsSettingsFromPrefs',
    r'double\s+_annualRatePctFromTextOrFallback',
    r'double\s+_applyAnnualRate'
]

ui_methods = [
    r'Widget\s+build\(BuildContext\s+context\)',
    r'Widget\s+_buildCategoryBox',
    r'Widget\s+_buildSectionBox'
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

# Create Logic
with open(logic_path, 'w', encoding='utf-8') as f:
    f.write("part of 'card_discount_stats_screen.dart';\n\n")
    f.write("extension CardDiscountStatsLogic on _CardDiscountStatsScreenState {\n")
    f.write(logic_code)
    f.write("}\n")

# Create UI
with open(ui_path, 'w', encoding='utf-8') as f:
    f.write("part of 'card_discount_stats_screen.dart';\n\n")
    f.write("extension CardDiscountStatsUI on _CardDiscountStatsScreenState {\n")
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

# Remove last import
idx_import = -1
for i, line in enumerate(lines):
    if line.startswith('import '):
        idx_import = i

if idx_import != -1:
    lines2 = orig_content.split('\n')
    lines2.insert(idx_import + 1, "\npart 'card_discount_stats_screen_logic.dart';\npart 'card_discount_stats_screen_ui.dart';\n")
    orig_content = '\n'.join(lines2)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(orig_content)

print("Extraction complete.")
