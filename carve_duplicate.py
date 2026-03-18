import re

with open('lib/screens/transaction_add_detailed_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# We need to find the specific methods and just remove them from text to form main.dart
# And remove non-specific from the other files.
# Actally, manually writing the file over might be easier.

from platform import python_version
print(python_version())
