import os

def extract_methods():
    source_file = 'lib/screens/phase3_demo_screen.dart'
    ui_file = 'lib/screens/phase3_demo_screen_ui.dart'
    
    with open(source_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    method_names = [
        'Widget _buildMultiTenantTab() {',
        'Widget _buildIsolationTile(String label, String value, Color color) {',
        'Widget _buildWorkflowTab() {',
        'Widget _buildIntegrationTab() {',
        'Widget _buildSectionHeader(String title, String subtitle) {',
        'Widget _buildScenarioCard({'
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
    if "part 'phase3_demo_screen_ui.dart';" not in joined_lines:
        imports_end = len(new_lines) - 1
        for i, line in enumerate(new_lines):
            if line.startswith('class '):
                imports_end = i
                break
        new_lines.insert(imports_end, "part 'phase3_demo_screen_ui.dart';\n\n")

    with open(source_file, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
        
    joined_extractions = "\n".join(extractions)
    ui_content = f"""part of 'phase3_demo_screen.dart';

extension Phase3DemoScreenUi on _Phase3DemoScreenState {{
{joined_extractions}
}}
"""
    with open(ui_file, 'w', encoding='utf-8') as f:
        f.write(ui_content)

    print("Methods extracted successfully.")

extract_methods()