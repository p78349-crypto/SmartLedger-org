import os

def extract_methods():
    source_file = 'lib/screens/root_security_setup_screen.dart'
    ui_file = 'lib/screens/root_security_setup_screen_ui.dart'
    
    with open(source_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    method_names = [
        'Widget _buildModeCard({'
    ]
    
    extractions = []
    indices_to_remove = set()
    
    for method_name in method_names:
        start_idx = -1
        for i, line in enumerate(lines):
            if method_name in line:
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
            print(f"Found Widget {method_name.replace('{','').strip()} at {start_idx}-{end_idx}")
            extractions.append("".join(lines[start_idx:end_idx+1]))
            for i in range(start_idx, end_idx+1):
                indices_to_remove.add(i)

    if not extractions:
        print("Nothing to extract.")
        return

    new_lines = [line for i, line in enumerate(lines) if i not in indices_to_remove]
    
    # insert part declaration if needed
    joined_lines = "".join(new_lines)
    if "part 'root_security_setup_screen_ui.dart';" not in joined_lines:
        for i, line in enumerate(new_lines):
            if line.startswith('part '):
                new_lines.insert(i+1, "part 'root_security_setup_screen_ui.dart';\n")
                break

    with open(source_file, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
        
    joined_extractions = "\n".join(extractions)
    ui_content = f"""part of 'root_security_setup_screen.dart';

extension RootSecuritySetupScreenUi on _RootSecuritySetupScreenState {{
{joined_extractions}
}}
"""
    with open(ui_file, 'w', encoding='utf-8') as f:
        f.write(ui_content)

    print("Methods extracted successfully.")

extract_methods()