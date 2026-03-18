import os

with open("lib/services/workflow_automation_engine.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

service_lines = []
models_lines = [
    "import 'package:flutter/material.dart';\n",
    "import 'dart:convert';\n\n"
]
widgets_lines = [
    "import 'package:flutter/material.dart';\n",
    "import 'package:intl/intl.dart';\n",
    "import '../services/workflow_automation_engine.dart';\n",
    "import '../models/workflow_models.dart';\n\n"
]

current_part = "service"

# Start parsing
for i, line in enumerate(lines):
    if line.startswith("class WorkflowDefinition {"):
        current_part = "models"
    elif line.startswith("class ApprovalPendingBadge"):
        current_part = "widgets"
        
    if current_part == "service":
        service_lines.append(line)
    elif current_part == "models":
        models_lines.append(line)
    elif current_part == "widgets":
        widgets_lines.append(line)

# Add export statements to the service file
service_lines_new = [
    "export '../models/workflow_models.dart';\n",
    "export '../widgets/workflow_widgets.dart';\n\n"
]
for line in service_lines:
    service_lines_new.append(line)

with open("lib/services/workflow_automation_engine.dart", "w", encoding="utf-8") as f:
    f.writelines(service_lines_new)

with open("lib/models/workflow_models.dart", "w", encoding="utf-8") as f:
    f.writelines(models_lines)

with open("lib/widgets/workflow_widgets.dart", "w", encoding="utf-8") as f:
    f.writelines(widgets_lines)

print("Workflow split completed.")
