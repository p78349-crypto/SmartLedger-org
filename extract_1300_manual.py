import os
import re

file_path = 'lib/screens/voice_dashboard_screen.dart'
logic_path = 'lib/screens/voice_dashboard_screen_logic.dart'

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

def find_line_idx(pattern, start_offset=0):
    for i in range(start_offset, len(lines)):
        if re.search(pattern, lines[i]):
            return i
    return -1

logic_methods = [
    r'void\s+_initAnimations\(\)',
    r'Future<void>\s+_initSpeech\(\)',
    r'void\s+_onSpeechStatus\(',
    r'Future<void>\s+_loadBudgetData\(\)',
    r'Future<void>\s+_startListening\(\)',
    r'Future<void>\s+_stopListening\(\)',
    r'Future<void>\s+_processVoiceCommand\(',
    r'bool\s+_isMonthlyClosingCommand\(',
    r'bool\s+_containsAmountHint\(',
    r'bool\s+_isExpenseCommand\(',
    r'bool\s+_isExpenseInputWithAmountCommand\(',
    r'bool\s+_isOpenExpenseInputCommand\(',
    r'bool\s+_isOpenIncomeInputCommand\(',
    r'bool\s+_isIngredientQueryCommand\(',
    r'bool\s+_isBudgetQueryCommand\(',
    r'bool\s+_isMenuRecommendCommand\(',
    r'bool\s+_isShoppingCartCommand\(',
    r'bool\s+_isShoppingCartAddCommand\(',
    r'bool\s+_isTodaySummaryCommand\(',
    r'bool\s+_isNavigationCommand\(',
    r'bool\s+_containsPageNavigation\(',
    r'bool\s+_isInventoryReportCommand\(',
    r'bool\s+_isFixedCostBriefingCommand\(',
    r'bool\s+_isSpendingAdviceCommand\(',
    r'bool\s+_isExceptionMarkingCommand\(',
    r'bool\s+_isWasteLogCommand\(',
    r'String\s+_extractExpenseDescription\(',
    r'void\s+_showMessage\(',
    r'void\s+_showFullVoiceGuide\(\)',
    r'void\s+_showHelpDialog\(\)'
]

extracted_code = ""
orig_content = "".join(lines)

for p in logic_methods:
    idx = find_line_idx(p, start_offset=40)
    if idx != -1:
        block = extract_block(idx)
        print(f"Extracted {p}")
        extracted_code += block + "\n"
        orig_content = orig_content.replace(block, "")

# move models and engine up to logic file safely
idx = orig_content.find("class _SealedSpeechEngine")
classes_to_move = ""
if idx != -1:
    classes_to_move = orig_content[idx:]
    orig_content = orig_content[:idx]

with open(logic_path, 'a', encoding='utf-8') as f:
    f.write("\n\nextension VoiceDashboardMoreLogic on _VoiceDashboardScreenState {\n")
    modified = extracted_code.replace("ScaffoldMessenger.of(context)", "if (!mounted) return;\n    ScaffoldMessenger.of(context)")
    modified = modified.replace("Navigator.pop(context)", "if (!mounted) return;\n    Navigator.pop(context)")
    f.write(modified)
    f.write("}\n\n")
    f.write(classes_to_move)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(orig_content)

print(f"Extraction complete.")
