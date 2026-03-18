import os

file_path = 'lib/screens/voice_dashboard_screen.dart'
logic_path = 'lib/screens/voice_dashboard_screen_logic.dart'
ui_path = 'lib/screens/voice_dashboard_screen_ui.dart'

with open(logic_path, 'w', encoding='utf-8') as f:
    f.write("""part of 'voice_dashboard_screen.dart';

extension VoiceDashboardLogic on _VoiceDashboardScreenState {

}
""")
    
with open(ui_path, 'w', encoding='utf-8') as f:
    f.write("""part of 'voice_dashboard_screen.dart';

extension VoiceDashboardUI on _VoiceDashboardScreenState {

}
""")

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

import_idx = -1
for i, l in enumerate(lines):
    if l.startswith('import ') or l.startswith('part '):
        import_idx = i

if import_idx != -1:
    lines.insert(import_idx+1, "part 'voice_dashboard_screen_logic.dart';\npart 'voice_dashboard_screen_ui.dart';\n")

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)

print('Initial Voice Dashboard setup done.')
