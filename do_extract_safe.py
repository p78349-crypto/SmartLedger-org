import os

file_path = 'lib/screens/transaction_add_detailed_screen.dart'
logic_path = 'lib/screens/transaction_add_detailed_screen_logic.dart'
ui_path = 'lib/screens/transaction_add_detailed_screen_ui.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

def get_method(lines, declare_str):
    start = -1
    for i, l in enumerate(lines):
        if declare_str in l and not l.strip().startswith('//') and not 'return ' in l and not 'await ' in l:
            start = i
            break
    if start == -1: return None, -1, -1
    
    braces = 0
    in_m = False
    for i in range(start, len(lines)):
        # Very simple brace counting
        l = lines[i]
        braces += l.count('{') - l.count('}')
        if braces > 0: in_m = True
        if in_m and braces == 0:
            return ''.join(lines[start:i+1]), start, i
    return None, -1, -1

logic_code, ls, le = get_method(lines, 'Future<void> _saveTransaction')
ui_code, us, ue = get_method(lines, 'List<Widget> _buildExpenseFields()')

if logic_code and ui_code:
    # Remove from bottom to top so indices don't shift!
    if le > ue:
        del lines[ls:le+1]
        del lines[us:ue+1]
    else:
        del lines[us:ue+1]
        del lines[ls:le+1]
        
    part_found = False
    import_idx = -1
    for i, l in enumerate(lines):
        if "part 'transaction_add_detailed_screen_ui.dart';" in l:
            part_found = True
        if l.startswith('import ') or l.startswith('part '):
            import_idx = i

    if not part_found and import_idx != -1:
        lines.insert(import_idx+1, "part 'transaction_add_detailed_screen_ui.dart';\npart 'transaction_add_detailed_screen_logic.dart';\n")

    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
        
    logic_template = f"""part of 'transaction_add_detailed_screen.dart';

extension TransactionAddDetailedLogic on _TransactionAddDetailedFormState {{
{logic_code}
}}
"""
    with open(logic_path, 'w', encoding='utf-8') as f:
        f.write(logic_template)

    ui_template = f"""part of 'transaction_add_detailed_screen.dart';

extension TransactionAddDetailedUI on _TransactionAddDetailedFormState {{
{ui_code}
}}
"""
    with open(ui_path, 'w', encoding='utf-8') as f:
        f.write(ui_template)
    
    print('Successful manual extraction of 2 functions.')
else:
    print('Failed to find methods.', ls, us)
