import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../navigation/app_routes.dart';
import '../screens/top_level_main_screen.dart';
import '../services/account_service.dart';
import '../theme/app_theme_seed_controller.dart';
import '../widgets/background_widget.dart';
import '../widgets/root_auth_gate.dart';
import '../widgets/special_backgrounds.dart';
import '../database/db_encryption_key_manager.dart';
import '../utils/online_password_key_backup_facade.dart';

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
        final isDefaultWhite =
            bgColor.toARGB32() == 0xFFFFFFFF ||
            bgColor.toARGB32() == 0xffffffff;

        if (theme.brightness == Brightness.dark && isDefaultWhite) {
          effectiveBgColor = theme.scaffoldBackgroundColor;
        }

        return Scaffold(
          backgroundColor: effectiveBgColor,
          extendBodyBehindAppBar: bgType == 'image' && bgImagePath != null,
          appBar: AppBar(
            title: const Text('기존 계정 선택'),
            backgroundColor: bgType == 'image' && bgImagePath != null
                ? Colors.transparent
                : null,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                // 로그아웃 시 secure storage 및 키백업 관련 설정 정리
                await const FlutterSecureStorage().deleteAll();
                final prefs = await SharedPreferences.getInstance();
                // 정책 모드는 유지하고 나머지 키백업 데이터만 삭제
                await prefs.remove('last_account_name');
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.key_outlined),
                tooltip: '암호화 키 복구',
                onPressed: () async {
                  final controller = TextEditingController();
                  final key = await showDialog<String>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('데이터베이스 암호화 키 복구'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '기기 변경 또는 앱 재설치 시 백업해둔 암호화 키를 입력하세요.\n'
                            '잘못된 키를 입력하면 기존 데이터를 읽을 수 없습니다.',
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              labelText: '암호화 키 (Base64)',
                              border: OutlineInputBorder(),
                            ),
                            autofocus: true,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('취소'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
                          child: const Text('복구'),
                        ),
                      ],
                    ),
                  );

                  if (key != null && key.isNotEmpty) {
                    final success = await DbEncryptionKeyManager.restoreKeyFromBackup(key);
                    if (!context.mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('암호화 키가 성공적으로 복구되었습니다.')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('잘못된 형식의 키입니다. (32바이트 Base64Url 필요)'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
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
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.2)),
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
                    final isRoot = accountName.trim().toUpperCase() == 'ROOT';
                    final account = accountService.getAccountByName(accountName);
                    final hasPassword = account?.password != null &&
                        account!.password!.isNotEmpty;

                    return ListTile(
                      leading: Icon(
                        isRoot 
                          ? Icons.admin_panel_settings
                          : (hasPassword ? Icons.lock : Icons.person),
                        color: isRoot ? Colors.amber : null,
                      ),
                      title: Text(accountName),
                      trailing: label == null
                          ? null
                          : Text(label, style: theme.textTheme.labelMedium),
                      onTap: () async {
                        // ROOT 선택 시 RootAuthGate로 보호된 ROOT 화면으로 이동
                        if (isRoot) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const RootAuthGate(
                                child: TopLevelMainScreen(),
                              ),
                            ),
                          );
                          return;
                        }
                        
                        final account = accountService.getAccountByName(
                          accountName,
                        );
                        if (account != null) {
                          // 비밀번호가 설정된 계정인 경우 비밀번호 확인
                          if (account.password != null &&
                              account.password!.isNotEmpty) {
                            final passwordController = TextEditingController();
                            final confirmed = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (dialogContext) => AlertDialog(
                                title: Text('$accountName 비밀번호 입력'),
                                content: TextField(
                                  controller: passwordController,
                                  obscureText: true,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    labelText: '비밀번호',
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (_) {
                                    Navigator.of(dialogContext).pop(true);
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop(false);
                                    },
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop(true);
                                    },
                                    child: const Text('확인'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirmed != true) {
                              passwordController.dispose();
                              return;
                            }
                            
                            if (passwordController.text != account.password) {
                              passwordController.dispose();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('비밀번호가 올바르지 않습니다'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            final password = passwordController.text;
                            passwordController.dispose();
                            final restoreResult = await OnlinePasswordKeyBackupFacade()
                                .restoreWithPassword(
                                  accountId: account.name,
                                  password: password,
                                );
                            
                            if (!context.mounted) return;
                            
                            if (!restoreResult.isSuccess && !restoreResult.isDisabled && !restoreResult.isOffline) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(restoreResult.message ?? 'DEK 복구에 실패했습니다'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                          
                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacementNamed(
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
