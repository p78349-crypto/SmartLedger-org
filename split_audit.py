import os

with open("lib/services/audit_log_service.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

service_lines = []
models_lines = [
    "import 'package:flutter/material.dart';\n\n"
]
widgets_lines = [
    "import 'package:flutter/material.dart';\n",
    "import 'package:intl/intl.dart';\n",
    "import '../services/audit_log_service.dart';\n",
    "import '../models/audit_models.dart';\n\n"
]

current_part = "service"

for i, line in enumerate(lines):
    if line.startswith("class AuditRealtimeSnapshot {"):
        current_part = "models"
    elif line.startswith("class AuditLogSummaryCard"):
        current_part = "widgets"
        
    if current_part == "service":
        service_lines.append(line)
    elif current_part == "models":
        models_lines.append(line)
    elif current_part == "widgets":
        widgets_lines.append(line)

service_lines_new = [
    "import '../models/audit_models.dart';\n",
    "import '../widgets/audit_widgets.dart';\n",
    "export '../models/audit_models.dart';\n",
    "export '../widgets/audit_widgets.dart';\n\n"
]
for line in service_lines:
    if line.startswith("import '../models/audit_models.dart';"):
        continue  # skip duplicate if it was there
    service_lines_new.append(line)

with open("lib/services/audit_log_service.dart", "w", encoding="utf-8") as f:
    f.writelines(service_lines_new)

with open("lib/models/audit_models.dart", "w", encoding="utf-8") as f:
    f.writelines(models_lines)

with open("lib/widgets/audit_widgets.dart", "w", encoding="utf-8") as f:
    f.writelines(widgets_lines)

print("Split completed.")
