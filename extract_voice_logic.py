import os

file_path = 'lib/screens/voice_dashboard_screen.dart'
logic_path = 'lib/screens/voice_dashboard_screen_logic.dart'

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
    'Future<VoiceCommandResult> _parseAndExecuteCommand(String command)',
    'Future<VoiceCommandResult> _handleMonthlyClosing(String command)',
    'Future<VoiceCommandResult> _handleExpenseCommand(String command)',
    'Future<VoiceCommandResult> _handleInventoryReport(String command)',
    'Future<VoiceCommandResult> _handleNavigationCommand(String cmd)',
    'Future<VoiceCommandResult> _handleShoppingCartAdd(String command)',
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
        
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
        
    with open(logic_path, 'r', encoding='utf-8') as f:
        logic_lines = f.readlines()
        
    last_brace_idx = -1
    for i in range(len(logic_lines)-1, -1, -1):
        if '}' in logic_lines[i]:
            last_brace_idx = i
            break
            
    if last_brace_idx != -1:
        logic_lines[last_brace_idx] = '\n\n' + '\n\n'.join(extracted_codes) + '\n}\n'
        with open(logic_path, 'w', encoding='utf-8') as f:
            f.writelines(logic_lines)
            
    print('Logic methods extracted successfully.')
else:
    print('Nothing to extract.')
