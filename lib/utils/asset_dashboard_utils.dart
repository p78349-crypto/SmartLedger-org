import '../utils/asset_management_utils.dart';
import '../widgets/asset_ui_widgets.dart';

export '../models/asset_dashboard_models.dart';
export '../utils/asset_management_utils.dart';
export '../widgets/asset_ui_widgets.dart';

/// ============================================================================
/// 하위호환성 별칭 (기존 코드와의 호환성 유지)
/// ============================================================================

@Deprecated('Use AssetManagementUtils instead')
typedef AssetDashboardUtils = AssetManagementUtils;

@Deprecated('Use AssetUIWidgets instead')
typedef AssetUIBuilder = AssetUIWidgets;
