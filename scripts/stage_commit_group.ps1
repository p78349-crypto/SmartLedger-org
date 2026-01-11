param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('1','2','3','4','5','6')]
  [string]$Group,

  [switch]$KeepIndex
)

$ErrorActionPreference = 'Stop'

try {
  Set-Location (git rev-parse --show-toplevel)
} catch {
}

if (-not $KeepIndex) {
  git restore --staged . | Out-Null
}

function Add-Paths([string[]]$paths) {
  foreach ($p in $paths) {
    if (Test-Path -LiteralPath $p) {
      git add -- $p
    }
  }
}

switch ($Group) {
  '1' {
    # CI / repo hygiene
    Add-Paths @(
      '.github/workflows/dart_ci.yml',
      '.gitattributes',
      '.gitignore',
      'scripts/ci_local.ps1',
      'scripts/stage_commit_group.ps1'
    )
  }
  '2' {
    # Fonts + pubspec + generated plugin registrants
    Add-Paths @(
      'assets/fonts',
      'pubspec.yaml',
      'pubspec.lock',
      'windows/flutter/generated_plugin_registrant.cc',
      'windows/flutter/generated_plugins.cmake',
      'linux/flutter/generated_plugin_registrant.cc',
      'linux/flutter/generated_plugins.cmake',
      'macos/Flutter/GeneratedPluginRegistrant.swift'
    )
  }
  '3' {
    # CEO/report feature set
    Add-Paths @(
      'lib/screens/ceo_assistant_dashboard.dart',
      'lib/screens/ceo_exception_details_screen.dart',
      'lib/screens/ceo_monthly_defense_report_screen.dart',
      'lib/screens/ceo_recovery_plan_screen.dart',
      'lib/screens/ceo_roi_detail_screen.dart',
      'lib/screens/monthly_profit_report_screen.dart',
      'lib/utils/roi_utils.dart',
      'lib/utils/misc_spending_utils.dart',
      'lib/utils/category_analysis.dart',
      'lib/utils/category_icon_map.dart',
      'lib/services/privacy_service.dart',
      'lib/services/policy_service.dart',
      'lib/services/asset_security_service.dart',
      'lib/navigation/app_router.dart',
      'lib/navigation/app_routes.dart',
      'lib/utils/pref_keys.dart',
      'test/integration/generate_monthly_report_test.dart'
    )
  }
  '4' {
    # Refund feature
    Add-Paths @(
      'lib/screens/refund_transactions_screen.dart',
      'lib/screens/transaction_detail_screen.dart',
      'test/features/refund_test.dart'
    )
  }
  '5' {
    # Deep link + visit price flow
    Add-Paths @(
      'lib/navigation/deep_link_handler.dart',
      'lib/navigation/route_param_validator.dart',
      'lib/services/deep_link_service.dart',
      'lib/services/deep_link_diagnostics.dart',
      'lib/services/bixby_deeplink_handler.dart',
      'lib/models/visit_price_entry.dart',
      'lib/services/visit_price_repository.dart',
      'lib/screens/visit_price_form_screen.dart'
    )
  }
  '6' {
    # Everything else (manual review recommended)
    Write-Host 'Group 6 is intentionally not auto-staged.'
    Write-Host 'Use: git add -p'
    exit 0
  }
}

Write-Host "`nStaged files:" 
$staged = git diff --cached --name-only
$staged | ForEach-Object { Write-Host "- $_" }
Write-Host "`nTip: commit with e.g. git commit -m \"...\"" 
