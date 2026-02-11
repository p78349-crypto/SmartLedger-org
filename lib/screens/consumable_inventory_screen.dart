import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';
import '../models/shopping_cart_item.dart';
import '../repositories/app_repositories.dart';
import '../services/consumable_inventory_service.dart';
import '../services/user_pref_service.dart';
import '../utils/wms_data_gateway.dart';
import 'consumable_inventory_dialogs.dart';
import 'consumable_inventory_widgets.dart';
import 'wms_io_screen.dart';

part 'consumable_inventory_screen_body.dart';
part 'consumable_inventory_screen_actions.dart';

class ConsumableInventoryScreen extends StatefulWidget {
  final String accountName;

  const ConsumableInventoryScreen({super.key, required this.accountName});

  @override
  State<ConsumableInventoryScreen> createState() =>
      _ConsumableInventoryScreenState();
}

class _ConsumableInventoryScreenState
    extends State<ConsumableInventoryScreen> {
  String _locationFilter = '전체';
  String _expiryFilter = '전체';

  Set<String> _countLikeUnits =
      UserPrefService.defaultCountLikeUnitsV1.toSet();

  String _formatQty(double value) {
    if (!value.isFinite) return '0';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.000001) {
      return rounded.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  bool _isCountLikeUnit(String unit) {
    final u = unit.trim();
    if (u.isEmpty) return false;
    return _countLikeUnits.contains(u);
  }

  @override
  void initState() {
    super.initState();
    WmsInventoryGateway.instance.getItems();
    _loadCountLikeUnits();
  }

  List<String> get _locationOptions => [
    '전체',
    ...ConsumableInventoryItem.locationOptions,
  ];

  List<String> get _expiryOptions => ['전체', '임박', '경과'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('식료품/생활용품 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: '개수형 단위 설정',
            onPressed: _showCountLikeUnitsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddItemDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WmsIoScreen(accountName: widget.accountName),
            ),
          );
        },
        tooltip: 'WMS 입출고',
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }
}
