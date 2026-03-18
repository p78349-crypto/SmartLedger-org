import os

file_path = 'lib/screens/root_account_manage_screen.dart'
logic_path = 'lib/screens/root_account_manage_screen_logic.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

def get_method(lines, declare_str):
    start = -1
    for i, l in enumerate(lines):
        if declare_str in l and not l.strip().startswith('//') and not 'return ' in l and not 'await ' in l and not l.strip().endswith(','):
            start = i
            break
    if start == -1: return None, -1, -1
    
    braces = 0
    in_m = False
    for i in range(start, len(lines)):
        l = lines[i]
        braces += l.count('{') - l.count('}')
        if braces > 0: in_m = True
        if in_m and braces == 0:
            return ''.join(lines[start:i+1]), start, i
    return None, -1, -1

logic_methods = [
    'Future<void> _showRootSecurityChoice() async {',
    'Future<void> _setupPin() async {',
    'Future<void> _setupBiometric() async {',
    'Future<void> _setupPassword() async {',
    'Future<void> _deleteAccount(Account account) async {',
    'Future<void> _showCreateAccountDialog() async {',
    'Future<void> _showPasswordDialog(Account account) async {',
    'Future<void> _setupAccountPin(Account account) async {',
    'Future<void> _setupAccountBiometric(Account account) async {',
    'Future<void> _setupAccountPassword(Account account) async {',
    'Future<void> _removeAccountSecurity(Account account) async {'
]

extracted_codes = []
bounds = []
for m in logic_methods:
    code, s, e = get_method(lines, m)
    if code:
        extracted_codes.append(code)
        bounds.append((s, e))
        print(f'Found {m} at {s}-{e}')
    else:
        print(f'Not found: {m}')

if bounds:
    bounds.sort(key=lambda x: x[0], reverse=True)
    for s, e in bounds:
        del lines[s:e+1]
        
    import_idx = -1
    part_exists = False
    for i, l in enumerate(lines):
        if l.startswith('import ') or l.startswith('part '):
            import_idx = i
        if 'part \'root_account_manage_screen_logic.dart\';' in l:
            part_exists = True

    if not part_exists and import_idx != -1:
        lines.insert(import_idx+1, "part 'root_account_manage_screen_logic.dart';\n")
        
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
        
    logic_template = f"""part of 'root_account_manage_screen.dart';

extension RootAccountManageLogic on _RootAccountManageScreenState {{
{chr(10).join(extracted_codes)}
}}
"""
    with open(logic_path, 'w', encoding='utf-8') as f:
        f.write(logic_template)
            
    print('Methods extracted successfully.')
else:
    print('Nothing to extract.')
