import os

def extract_methods():
    source_file = 'lib/screens/root_memo_list_screen.dart'
    logic_file = 'lib/screens/root_memo_list_screen_logic.dart'
    
    with open(source_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    method_names = [
        '_onSearchChanged',
        '_loadMemos',
        '_addMemo',
        '_editMemo',
        '_deleteMemo',
        '_togglePin',
        '_showMemoDialog'
    ]
    
    extractions = []
    indices_to_remove = set()
    
    for method_name in method_names:
        start_idx = -1
        for i, line in enumerate(lines):
            if method_name in line and '{' in line and (line.strip().startswith('void ') or line.strip().startswith('Future<')):
                start_idx = i
                break
                
        if start_idx == -1:
            print(f"Not found: {method_name}")
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
    
    # insert part declaration if needed
    joined_lines = "".join(new_lines)
    if "part 'root_memo_list_screen_logic.dart';" not in joined_lines:
        imports_end = len(new_lines) - 1
        for i, line in enumerate(new_lines):
            if line.startswith('class '):
                imports_end = i
                break
        new_lines.insert(imports_end, "part 'root_memo_list_screen_logic.dart';\n\n")

    with open(source_file, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
        
    joined_extractions = "\n".join(extractions)
    logic_content = f"""part of 'root_memo_list_screen.dart';

extension RootMemoListScreenLogic on _RootMemoListScreenState {{
{joined_extractions}
}}
"""
    with open(logic_file, 'w', encoding='utf-8') as f:
        f.write(logic_content)

    print("Logic methods extracted successfully.")

extract_methods()