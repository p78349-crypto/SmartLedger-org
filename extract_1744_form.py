import os

file_path = 'lib/screens/transaction_add_detailed_screen.dart'
form_path = 'lib/screens/transaction_add_detailed_screen_form.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_idx = 172 # 0-based
form_code = "".join(lines[start_idx:])

with open(form_path, 'w', encoding='utf-8') as f:
    f.write("part of 'transaction_add_detailed_screen.dart';\n\n")
    f.write(form_code)

orig_content = "".join(lines[:start_idx])

# inject part statement
idx_part = -1
for i, line in enumerate(lines[:start_idx]):
    if line.startswith("part 'transaction_add_detailed_screen_ui.dart';"):
        idx_part = i

lines2 = orig_content.split('\n')
if idx_part != -1:
    lines2.insert(idx_part, "part 'transaction_add_detailed_screen_form.dart';")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines2))

print("Extraction complete.")
