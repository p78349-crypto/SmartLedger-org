import 'package:flutter/material.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/main_feature_icon_catalog.dart';

class Page1FullScreenAdOverlay extends StatefulWidget {
  final VoidCallback onClose;

  const Page1FullScreenAdOverlay({super.key, required this.onClose});

  @override
  State<Page1FullScreenAdOverlay> createState() =>
      _Page1FullScreenAdOverlayState();
}

class _Page1FullScreenAdOverlayState extends State<Page1FullScreenAdOverlay> {
  bool? _enabled;

  @override
  void initState() {
    super.initState();
    _loadEnabled();
  }

  Future<void> _loadEnabled() async {
    final enabled = await UserPrefService.getPage1FullScreenAdEnabled();
    if (!mounted) return;
    setState(() => _enabled = enabled);
    if (!enabled) {
      // If disabled, prefer to notify caller to not show overlay.
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onClose());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // If we haven't loaded the preference yet, return nothing to avoid
    // flashing the overlay. If explicitly disabled, render nothing.
    // Also don't render if main pages are blocked globally.
    if (MainFeatureIconCatalog.pageCount == 0) return const SizedBox.shrink();

    if (_enabled == null || _enabled == false) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Block interaction with the underlying page/banner.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onClose,
          child: ColoredBox(
            color: theme.colorScheme.scrim.withValues(alpha: 0.7),
            child: SafeArea(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(
                    '광고 영역 (출시 전: 기본 비노출)\n\n터치하면 닫힙니다',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
