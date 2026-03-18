import sys

content = open('lib/screens/help_guides_screens.dart', 'r', encoding='utf-8').read()
idx = content.find('class HelpUserManualScreen extends StatelessWidget')
if idx != -1:
    part1 = content[:idx]
    part2 = content[idx:]
    
    # modify part1
    lines = part1.split('\n')
    lines.insert(2, "part 'help_guides_screens_extra.dart';")
    open('lib/screens/help_guides_screens.dart', 'w', encoding='utf-8').write('\n'.join(lines))
    
    # write part2
    part2_content = "part of 'help_guides_screens.dart';\n\n" + part2
    open('lib/screens/help_guides_screens_extra.dart', 'w', encoding='utf-8').write(part2_content)
    print('Split successful')
else:
    print('Failed to find splitting point')
