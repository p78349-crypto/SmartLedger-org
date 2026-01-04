import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/theme/app_theme_seed_controller.dart';
import 'package:smart_ledger/widgets/background_widget.dart';
import 'package:smart_ledger/widgets/special_backgrounds.dart';

class AccountSelectScreen extends StatelessWidget {
  final List<String> accounts;
  const AccountSelectScreen({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    final accountService = AccountService();

    final labels = <String, String>{};
    int userIndex = 0;
    for (final name in accounts) {
      if (name.trim().toUpperCase() == 'ROOT') {
        labels[name] = 'ROOT';
        continue;
      }
      userIndex++;
      if (userIndex == 1) {
        labels[name] = '유저1';
      } else if (userIndex == 2) {
        labels[name] = '유저2';
      }
    }

    return ListenableBuilder(
      listenable: Listenable.merge([
        BackgroundHelper.colorNotifier,
        BackgroundHelper.typeNotifier,
        BackgroundHelper.imagePathNotifier,
        BackgroundHelper.blurNotifier,
        AppThemeSeedController.instance.presetId,
      ]),
      builder: (context, _) {
        final bgColor = BackgroundHelper.colorNotifier.value;
        final bgType = BackgroundHelper.typeNotifier.value;
        final bgImagePath = BackgroundHelper.imagePathNotifier.value;
        final bgBlur = BackgroundHelper.blurNotifier.value;
        final presetId = AppThemeSeedController.instance.presetId.value;
        final theme = Theme.of(context);

        // In dark mode, if the background color is still the default white,
        // we should use the theme's scaffold background color instead.
        Color effectiveBgColor = bgColor;
        final isDefaultWhite = bgColor.toARGB32() == 0xFFFFFFFF ||
            bgColor.toARGB32() == 0xffffffff;

        if (theme.brightness == Brightness.dark && isDefaultWhite) {
          effectiveBgColor = theme.scaffoldBackgroundColor;
        }

        return Scaffold(
          backgroundColor: effectiveBgColor,
          extendBodyBehindAppBar: bgType == 'image' && bgImagePath != null,
          appBar: AppBar(
            title: const Text('기존 계정 선택'),
            backgroundColor:
                bgType == 'image' && bgImagePath != null
                    ? Colors.transparent
                    : null,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Stack(
            children: [
              // 1. Base Background (Color or Image)
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    if (bgType == 'image' && bgImagePath != null) {
                      return Image.file(
                        File(bgImagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            ColoredBox(color: effectiveBgColor),
                      );
                    }

                    if (presetId == 'midnight_gold') {
                      return MidnightGoldBackground(
                        baseColor: effectiveBgColor,
                      );
                    } else if (presetId == 'starlight_navy') {
                      return StarlightNavyBackground(
                        baseColor: effectiveBgColor,
                      );
                    }
                    return ColoredBox(color: effectiveBgColor);
                  },
                ),
              ),

              // 2. Blur Effect (if image)
              if (bgType == 'image' && bgImagePath != null && bgBlur > 0)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: bgBlur, sigmaY: bgBlur),
                    child: const ColoredBox(color: Colors.transparent),
                  ),
                ),

              // 3. Dark Overlay for images to ensure readability
              if (bgType == 'image' && bgImagePath != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                ),

              // 4. Content
              SafeArea(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24.0),
                  itemCount: accounts.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final accountName = accounts[index];
                    final label = labels[accountName];

                    return ListTile(
                      title: Text(accountName),
                      trailing:
                          label == null
                              ? null
                              : Text(
                                label,
                                style: theme.textTheme.labelMedium,
                              ),
                      onTap: () {
                        final account = accountService.getAccountByName(
                          accountName,
                        );
                        if (account != null) {
                          Navigator.of(context).pushNamed(
                            AppRoutes.accountMain,
                            arguments: AccountMainArgs(
                              accountName: account.name,
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
