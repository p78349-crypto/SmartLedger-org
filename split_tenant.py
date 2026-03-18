import os

with open("_backup_before_edit/2026-03-18_200530/lib/services/multi_tenant_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

service_lines = []
models_lines = [
    "import 'package:flutter/material.dart';\n\n",
]
widgets_lines = [
    "import 'package:flutter/material.dart';\n",
    "import '../services/multi_tenant_service.dart';\n",
    "import '../models/tenant.dart';\n\n"
]

current_part = "service"

for i, line in enumerate(lines):
    if line.startswith("enum TenantPlan {"):
        current_part = "models"
    elif line.startswith("class TenantSwitcher"):
        current_part = "widgets"
        
    if current_part == "service":
        service_lines.append(line)
    elif current_part == "models":
        models_lines.append(line)
    elif current_part == "widgets":
        widgets_lines.append(line)

# Add import '../models/tenant.dart'; to service file
service_lines_new = []
imports_done = False
for line in service_lines:
    service_lines_new.append(line)
    if "import 'package:shared_preferences/shared_preferences.dart';" in line and not imports_done:
        service_lines_new.append("import '../models/tenant.dart';\n")
        imports_done = True

with open("lib/services/multi_tenant_service.dart", "w", encoding="utf-8") as f:
    f.writelines(service_lines_new)

with open("lib/models/tenant.dart", "w", encoding="utf-8") as f:
    f.writelines(models_lines)

with open("lib/widgets/tenant_widgets.dart", "w", encoding="utf-8") as f:
    f.writelines(widgets_lines)

print("Split completed.")
