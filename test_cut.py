import sys

def cut_method(file_path, method_decl):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    start_line = -1
    for i, line in enumerate(lines):
        if method_decl in line and not line.strip().startswith('//') and not 'return ' in line and not 'await ' in line:
            start_line = i
            break
            
    if start_line == -1: return None
    
    braces = 0
    in_method = False
    end_line = -1
    for i in range(start_line, len(lines)):
        line = lines[i]
        # Skip string braces
        cleaned_line = line.replace('{', '').replace('}', '') if '{''}' in line else line
        braces += line.count('{')
        braces -= line.count('}')
        if braces > 0: in_method = True
        if in_method and braces == 0:
            end_line = i
            break
            
    if end_line != -1:
        extracted = "".join(lines[start_line:end_line+1])
        # Replace method with empty lines or something, wait no, just return it.
        # actually, write it to screen.
        print(f'{method_decl}: lines {start_line+1} to {end_line+1}')
        return extracted
    return None

c1 = cut_method('lib/screens/transaction_add_detailed_screen.dart', 'Future<void> _saveTransaction')
c2 = cut_method('lib/screens/transaction_add_detailed_screen.dart', 'List<Widget> _buildExpenseFields()')

print(f'_saveTransaction Length: {len(c1) if c1 else 0}')
print(f'_buildExpenseFields Length: {len(c2) if c2 else 0}')
