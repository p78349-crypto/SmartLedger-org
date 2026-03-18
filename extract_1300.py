import os

file_path = 'lib/screens/voice_dashboard_screen.dart'
logic_path = 'lib/screens/voice_dashboard_screen_logic.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

methods_to_extract = []
brace_count = 0
in_target_class = False

i = 0
while i < len(lines):
    line = lines[i]
    if line.startswith('class _VoiceDashboardScreenState'):
        in_target_class = True
    
    if in_target_class:
        if '{' in line:
            # Check if this is a top-level method
            if brace_count == 1:
                stripped = line.strip()
                if (stripped.startswith('Future<') or stripped.startswith('void _') or stripped.startswith('bool _') or stripped.startswith('String _')) and not stripped.startswith('void initState') and not stripped.startswith('void dispose') and not stripped.startswith('Widget '):
                    # Found a method to extract
                    method_lines = []
                    method_brace_count = 0
                    started = False
                    
                    # Read the whole method
                    j = i
                    while j < len(lines):
                        m_line = lines[j]
                        method_lines.append(m_line)
                        if '{' in m_line:
                            method_brace_count += m_line.count('{')
                            started = True
                        if '}' in m_line:
                            method_brace_count -= m_line.count('}')
                            
                        if started and method_brace_count == 0:
                            break
                        j += 1
                    
                    methods_to_extract.append(method_lines)
                    i = j # Skip to end of method
        
        brace_count += line.count('{')
        brace_count -= line.count('}')
        
        if brace_count == 0 and '}' in line:
            in_target_class = False
    i += 1

extracted_code = ""
for m in methods_to_extract:
    extracted_code += "".join(m) + "\n"

# Remove extracted blocks from main file
orig_content = "".join(lines)
for m in methods_to_extract:
    block = "".join(m)
    orig_content = orig_content.replace(block, "")

# Find classes at the bottom to move to logic
# "class _SealedSpeechEngine" and down
split_idx = orig_content.find("class _SealedSpeechEngine")
classes_to_move = ""
if split_idx != -1:
    classes_to_move = orig_content[split_idx:]
    orig_content = orig_content[:split_idx]

with open(logic_path, 'a', encoding='utf-8') as f:
    f.write("\n\nextension VoiceDashboardMoreLogic on _VoiceDashboardScreenState {\n")
    modified = extracted_code.replace("ScaffoldMessenger.of(context)", "if (!mounted) return;\n    ScaffoldMessenger.of(context)")
    modified = modified.replace("Navigator.pop(context)", "if (!mounted) return;\n    Navigator.pop(context)")
    f.write(modified)
    f.write("}\n\n")
    f.write(classes_to_move)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(orig_content)

print(f"Extraction complete. Found {len(methods_to_extract)} methods.")
