import os

def extract_methods():
    source_file = 'lib/screens/one_hundred_million_project_screen.dart'
    logic_file = 'lib/screens/one_hundred_million_project_screen_logic.dart'
    
    with open(source_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    method_names = [
        '_loadData',
        '_saveData',
        '_saveProjectSettings',
        '_markSettingsDirty',
        '_calculateTotal'
    ]
    
    extractions = []
    indices_to_remove = set()
    
    for method_name in method_names:
        start_idx = -1
        for i, line in enumerate(lines):
            if method_name in line and '{' in line and ('void' in line or 'Future' in line):
                start_idx = i
                break
                
        if start_idx == -1:
            continue
            
        brace_count = 0
        end_idx = -1
        
        for i in range(start_idx, len(lines)):
            line = lines[i]
            if '{' in line:
                brace_count += line.count('{')
            if '}' in line:
                brace_count -= line.count('}')
                
            if brace_count == 0:
                end_idx = i
                break
                
        if start_idx != -1 and end_idx != -1:
            print(f"Found logic {method_name} at {start_idx}-{end_idx}")
            extractions.append("".join(lines[start_idx:end_idx+1]))
            for i in range(start_idx, end_idx+1):
                indices_to_remove.add(i)

    if not extractions:
        print("No methods found")
        return

    new_lines = [line for i, line in enumerate(lines) if i not in indices_to_remove]
    
    with open(source_file, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
        
    joined_extractions = "\n".join(extractions)
    logic_content = f"""part of 'one_hundred_million_project_screen.dart';

extension OneHundredMillionProjectScreenLogic on _OneHundredMillionProjectScreenState {{
{joined_extractions}
}}
"""
    with open(logic_file, 'w', encoding='utf-8') as f:
        f.write(logic_content)

    print("Logic methods extracted successfully.")

extract_methods()