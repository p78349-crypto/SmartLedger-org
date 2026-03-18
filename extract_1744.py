import os
import re

file_path = 'lib/screens/transaction_add_detailed_screen.dart'
logic_path = 'lib/screens/transaction_add_detailed_screen_logic.dart'

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
    r'Future<void>\s+triggerAutoSubmit\(\)',
    r'bool\s+_isShoppingCategory\(',
    r'Future<String\?>\s+_buildShoppingSpendComparisonTooltip\(',
    r'Future<void>\s+_loadShoppingCategoryHints\(\)',
    r'Future<void>\s+_predictCategoryWithAI\(\)',
    r'void\s+_handleDescriptionChanged\(',
    r'Future<void>\s+_loadSortedCategories\(\)',
    r'Future<void>\s+_loadRecentInputs\(\)',
    r'Future<void>\s+_showRecentInputPicker\(',
    r'Future<void>\s+openShoppingCartPicker\(\)',
    r'Future<void>\s+confirmAndOpenShoppingCartPicker\(\)',
    r'Future<void>\s+_saveDraft\(\)',
    r'Future<void>\s+_clearDraft\(\)',
    r'Future<void>\s+_loadDraftIfRecent\(\)',
    r'void\s+_captureInitialSnapshotIfNeeded\(\)',
    r'Future<void>\s+promptRevertToInitial\(\)',
    r'void\s+_restoreFromInitialSnapshot\(',
    r'Future<bool>\s+_maybeConfirmPriceRise\(',
    r'void\s+_updateAmount\(\)',
    r'void\s+_applyIncomeDefaultCategory\(\)',
    r'Future<void>\s+_restoreLastCategoryForType\(',
    r'Future<void>\s+_pickTransactionDate\(\)',
    r'String\?\s+_validatePositiveAmount\(',
    r'Future<void>\s+_saveAndContinue\(\)'
]

extracted_code = ""
orig_content = "".join(lines)

for p in logic_methods:
    idx = find_line_idx(p, start_offset=246)
    if idx != -1:
        block = extract_block(idx)
        extracted_code += block + "\n"
        orig_content = orig_content.replace(block, "")

# Append to logic file
with open(logic_path, 'a', encoding='utf-8') as f:
    f.write("\n\nextension TransactionAddDetailedFormMoreLogic on _TransactionAddDetailedFormState {\n")
    # inject `if (!context.mounted) return;` safely for ScaffoldMessenger and Navigator
    # Note: Because the current dart codebase uses both mounted and context checks we will not rigidly apply regex because it might break syntax for nested scopes. We will just use string replace.
    modified = extracted_code.replace("ScaffoldMessenger.of(context)", "if (!mounted) return;\n    ScaffoldMessenger.of(context)")
    modified = modified.replace("Navigator.of(context)", "if (!mounted) return;\n    Navigator.of(context)")
    f.write(modified)
    f.write("}\n")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(orig_content)

print("Extraction complete.")
