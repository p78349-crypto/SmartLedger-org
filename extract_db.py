import re

with open("lib/database/app_database.dart", "r", encoding="utf-8") as f:
    text = f.read()

pattern = r"(?P<indent>  )(@override\n  MigrationStrategy get migration => MigrationStrategy\([\s\S]*?\n  \);)"
match = re.search(pattern, text)

if match:
    mig_code = match.group(2)
    # Replace in original text
    new_text = text[:match.start(2)] + "MigrationStrategy get migration => this.migrationStrategy;" + text[match.end(2):]
    
    new_text = new_text.replace("part 'app_database.g.dart';", "part 'app_database.g.dart';\npart 'app_database_migration.dart';")
    
    with open("lib/database/app_database.dart", "w", encoding="utf-8") as f:
        f.write(new_text)
        
    with open("lib/database/app_database_migration.dart", "w", encoding="utf-8") as f:
        mig_content_ext = "part of 'app_database.dart';\n\nextension AppDatabaseMigration on AppDatabase {\n  MigrationStrategy get migrationStrategy {\n    return " + mig_code[mig_code.find("MigrationStrategy("):] + "\n  }\n}\n"
        f.write(mig_content_ext)
    print("Success")
else:
    print("Pattern not found")
