part of 'card_discount_stats_screen.dart';

extension CardDiscountStatsLogic on _CardDiscountStatsScreenState {
  Future<void> _loadPointsSettingsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final rate =
        prefs.getDouble(PrefKeys.project100mPointsAnnualRatePctV1) ??
        _CardDiscountStatsScreenState._defaultAnnualRatePct;
    final modeRaw =
        prefs.getInt(PrefKeys.project100mPointsInterestModeV1) ??
        _CardDiscountStatsScreenState._modeSimpleAnnual;
    final mode =
        (modeRaw == _CardDiscountStatsScreenState._modeSimpleAnnual ||
            modeRaw == _CardDiscountStatsScreenState._modeCompoundYearly ||
            modeRaw == _CardDiscountStatsScreenState._modeCompoundMonthly)
        ? modeRaw
        : _CardDiscountStatsScreenState._modeSimpleAnnual;

    if (!mounted) return;
    setState(() {
      _annualRatePct = rate.clamp(0.0, 100.0);
      _annualRateController.text = _annualRatePct.toStringAsFixed(1);
      _interestMode = mode;
    });
  }

  double _annualRatePctFromTextOrFallback(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return _annualRatePct;

    final m = RegExp(r'[-+]?\d*\.?\d+').firstMatch(trimmed);
    final raw = m?.group(0);
    if (raw == null) return _annualRatePct;

    final parsed = double.tryParse(raw);
    if (parsed == null) return _annualRatePct;
    return parsed.clamp(0.0, 100.0);
  }

  double _applyAnnualRate(
    double presentValue, {
    required int years,
    required double annualRatePct,
  }) {
    if (presentValue <= 0) return 0;
    final r = (annualRatePct / 100.0).clamp(0.0, 100.0);
    if (r == 0 || years <= 0) return presentValue;

    switch (_interestMode) {
      case _CardDiscountStatsScreenState._modeSimpleAnnual:
        // Simple interest: FV = PV * (1 + r * years)
        return presentValue * (1 + r * years);
      case _CardDiscountStatsScreenState._modeCompoundMonthly:
        // Monthly compounding: FV = PV * (1 + r/12)^(12*years)
        return presentValue * math.pow(1 + (r / 12.0), 12 * years).toDouble();
      case _CardDiscountStatsScreenState._modeCompoundYearly:
      default:
        // Yearly compounding: FV = PV * (1 + r)^years
        return presentValue * math.pow(1 + r, years).toDouble();
    }
  }
}
