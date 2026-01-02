import 'package:flutter/material.dart';

/// Central single-source for commonly reused IconData across `lib/utils`.
///
/// Purpose: reduce repeated literal `Icons.*` usage and make future swaps
/// (theme / glyph changes) easier by editing one place.
class IconCatalog {
  const IconCatalog._();

  static const IconData addCircle = Icons.add_circle;
  static const IconData addBusiness = Icons.add_business;
  static const IconData receiptLongOutlined = Icons.receipt_long_outlined;
  static const IconData receiptLong = Icons.receipt_long;
  static const IconData dashboard = Icons.dashboard;
  static const IconData trendingUp = Icons.trending_up;
  static const IconData assessment = Icons.assessment;
  static const IconData list = Icons.list;
  static const IconData search = Icons.search;
  static const IconData accountBalanceWallet = Icons.account_balance_wallet;
  static const IconData eventAvailable = Icons.event_available;
  static const IconData settings = Icons.settings;
  static const IconData displaySettings = Icons.display_settings;
  static const IconData language = Icons.language;
  static const IconData attachMoney = Icons.attach_money;
  static const IconData apartment = Icons.apartment;
  static const IconData accountBalance = Icons.account_balance;
  static const IconData currencyBitcoin = Icons.currency_bitcoin;
  static const IconData payments = Icons.payments;
  static const IconData categoryOutlined = Icons.category_outlined;
  static const IconData paymentsOutlined = Icons.payments_outlined;
  static const IconData schedule = Icons.schedule;
  // Additional commonly used icons across utils
  static const IconData calendarToday = Icons.calendar_today;
  static const IconData timeline = Icons.timeline;
  static const IconData calendarViewMonth = Icons.calendar_view_month;
  static const IconData dateRange = Icons.date_range;
  static const IconData autoGraph = Icons.auto_graph;

  static const IconData looksOne = Icons.looks_one;
  static const IconData looks3 = Icons.looks_3;
  static const IconData looks6 = Icons.looks_6;
  static const IconData trendingDown = Icons.trending_down;
  static const IconData savingsOutlined = Icons.savings_outlined;
  static const IconData savings = Icons.savings;
  static const IconData compareArrows = Icons.compare_arrows;
  static const IconData moving = Icons.moving;
  static const IconData fullscreen = Icons.fullscreen;
  static const IconData download = Icons.download;
  static const IconData tune = Icons.tune;
  static const IconData zoomIn = Icons.zoom_in;
  static const IconData refresh = Icons.refresh;
  static const IconData chevronRight = Icons.chevron_right;
  static const IconData wbSunny = Icons.wb_sunny;
  static const IconData wbCloudy = Icons.wb_cloudy;
  static const IconData cloudQueue = Icons.cloud_queue;
  static const IconData acUnit = Icons.ac_unit;
  static const IconData history = Icons.history;
  static const IconData autoAwesome = Icons.auto_awesome;
  static const IconData barChart = Icons.bar_chart;
  static const IconData showChart = Icons.show_chart;
  static const IconData pieChart = Icons.pie_chart;
  static const IconData gridView = Icons.grid_view;
  static const IconData errorOutline = Icons.error_outline;
  static const IconData checkCircleOutline = Icons.check_circle_outline;
  static const IconData radioButtonChecked = Icons.radio_button_checked;
  static const IconData radioButtonOff = Icons.radio_button_off;
  static const IconData checkCircle = Icons.check_circle;
  static const IconData refund = Icons.replay;

  static const IconData edit = Icons.edit;
  static const IconData editOutlined = Icons.edit_outlined;
  static const IconData delete = Icons.delete;
  static const IconData moveDown = Icons.move_down;
  static const IconData receipt = Icons.receipt;
  static const IconData chevronLeft = Icons.chevron_left;
  static const IconData password = Icons.password;
  static const IconData lock = Icons.lock;
  static const IconData lockOpen = Icons.lock_open;
  static const IconData inventory2 = Icons.inventory_2;

  static const IconData insightsOutlined = Icons.insights_outlined;
  static const IconData infoOutline = Icons.info_outline;
  static const IconData swapVert = Icons.swap_vert;
  static const IconData arrowBackIosNew = Icons.arrow_back_ios_new;
  static const IconData articleOutlined = Icons.article_outlined;
  static const IconData autoGraphOutlined = Icons.auto_graph_outlined;
  static const IconData removeCircleOutline = Icons.remove_circle_outline;
  static const IconData addCircleOutline = Icons.add_circle_outline;
  static const IconData warningAmberRounded = Icons.warning_amber_rounded;

  // Missing Feature Icons (Added 2025-12-25)
  static const IconData adminPanelSettings = Icons.admin_panel_settings;
  static const IconData shoppingCart = Icons.shopping_cart;
  static const IconData warningAmber = Icons.warning_amber;
  static const IconData backup = Icons.backup;
  static const IconData dashboardCustomizeOutlined =
      Icons.dashboard_customize_outlined;
  static const IconData pieChartOutline = Icons.pie_chart_outline;
  static const IconData quickreplyOutlined = Icons.quickreply_outlined;
  static const IconData factCheckOutlined = Icons.fact_check_outlined;
  static const IconData listAlt = Icons.list_alt;
  static const IconData imageOutlined = Icons.image_outlined;
  static const IconData fingerprint = Icons.fingerprint;
  static const IconData lockOutline = Icons.lock_outline;
  static const IconData passwordOutlined = Icons.password_outlined;
  static const IconData eventRepeat = Icons.event_repeat;
  static const IconData add = Icons.add;
  static const IconData clear = Icons.clear;
  static const IconData close = Icons.close;
  static const IconData deleteOutline = Icons.delete_outline;
  static const IconData arrowBack = Icons.arrow_back;
  static const IconData arrowForward = Icons.arrow_forward;
  static const IconData menu = Icons.menu;
  static const IconData moreVert = Icons.more_vert;
  static const IconData moreHoriz = Icons.more_horiz;
  static const IconData help = Icons.help;
  static const IconData restartAlt = Icons.restart_alt;
  static const IconData radioButtonUnchecked = Icons.radio_button_unchecked;
  static const IconData payment = Icons.payment;
  static const IconData localOffer = Icons.local_offer;
  static const IconData creditCard = Icons.credit_card;
  static const IconData percent = Icons.percent;
  static const IconData cardGiftcard = Icons.card_giftcard;
  static const IconData arrowDownward = Icons.arrow_downward;
  static const IconData inboxOutlined = Icons.inbox_outlined;
  static const IconData visibilityOffOutlined = Icons.visibility_off_outlined;
  static const IconData calendarTodayOutlined = Icons.calendar_today_outlined;
  static const IconData check = Icons.check;
  static const IconData openWithOutlined = Icons.open_with_outlined;

  // Added during refactoring 2025-12-25
  static const IconData navigateNext = Icons.navigate_next;
  static const IconData deleteSweepOutlined = Icons.delete_sweep_outlined;
  static const IconData expandMore = Icons.expand_more;
  static const IconData calculate = Icons.calculate;
  static const IconData arrowForwardIos = Icons.arrow_forward_ios;
  static const IconData accountTreeOutlined = Icons.account_tree_outlined;
  static const IconData accountBalanceWalletOutlined =
      Icons.account_balance_wallet_outlined;
  static const IconData shieldOutlined = Icons.shield_outlined;
  static const IconData verifiedUserOutlined = Icons.verified_user_outlined;
  static const IconData remove = Icons.remove;
  static const IconData filterList = Icons.filter_list;

  // Settings / Theme
  static const IconData paletteOutlined = Icons.palette_outlined;
  static const IconData keyboardAltOutlined = Icons.keyboard_alt_outlined;
  static const IconData brightnessAutoOutlined = Icons.brightness_auto_outlined;
  static const IconData lightModeOutlined = Icons.light_mode_outlined;
  static const IconData darkModeOutlined = Icons.dark_mode_outlined;
}

