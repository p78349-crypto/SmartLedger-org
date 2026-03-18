import os

file_path = 'lib/screens/transaction_add_detailed_screen.dart'
ui_path = 'lib/screens/transaction_add_detailed_screen_ui.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

def get_method(lines, declare_str):
    start = -1
    for i, l in enumerate(lines):
        # We need to match precisely the line starting the method
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

ui_methods = [
    'Widget _buildStoreOrBuyerField()',
    'Widget _buildInlineHeader()',
    'Widget _buildSaveButtons({bool compact = false})',
    'Widget _buildPaymentField({',
    'Widget _buildSavingsAllocationSelector(ThemeData theme)',
    'Widget _buildSavingsDateField()',
    'Widget _buildDescriptionInput({'
]

extracted_codes = []
bounds = []
for m in ui_methods:
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
        
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
        
    with open(ui_path, 'r', encoding='utf-8') as f:
        ui_lines = f.readlines()
        
    last_brace_idx = -1
    for i in range(len(ui_lines)-1, -1, -1):
        if '}' in ui_lines[i]:
            last_brace_idx = i
            break
            
    if last_brace_idx != -1:
        ui_lines[last_brace_idx] = '\n\n' + '\n\n'.join(extracted_codes) + '\n}\n'
        with open(ui_path, 'w', encoding='utf-8') as f:
            f.writelines(ui_lines)
            
    print('Extra UI methods extracted successfully.')
else:
    print('Nothing to extract.')
