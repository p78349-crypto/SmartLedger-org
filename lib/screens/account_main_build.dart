part of 'account_main_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension AccountMainBuild on _AccountMainScreenState {
  Widget _buildMain(BuildContext context) {
    // Phase 1: Smart style horizontal main pages (icons-only).
    // Top banner removed: only render the PageView.
    return ListenableBuilder(
      listenable: Listenable.merge([
        BackgroundHelper.colorNotifier,
        BackgroundHelper.typeNotifier,
        BackgroundHelper.imagePathNotifier,
        BackgroundHelper.blurNotifier,
      ]),
      builder: (context, _) {
        final bgColor = BackgroundHelper.colorNotifier.value;
        final bgType = BackgroundHelper.typeNotifier.value;
        final bgImagePath = BackgroundHelper.imagePathNotifier.value;
        final bgBlur = BackgroundHelper.blurNotifier.value;

        final presetId = AppThemeSeedController.instance.presetId.value;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        // DEBUG: 화면 크기 출력 (프로토타입/개발 모드 전용, 출시 전 자동 제거됨)
        if (kDebugMode) {
          final size = MediaQuery.of(context).size;
          final padding = MediaQuery.of(context).padding;
          debugPrint(
            '📱 화면 크기: ${size.width.toStringAsFixed(1)} '
            'x ${size.height.toStringAsFixed(1)}',
          );
          debugPrint(
            '📱 SafeArea 여백: top=${padding.top.toStringAsFixed(1)}, '
            'bottom=${padding.bottom.toStringAsFixed(1)}, '
            'left=${padding.left.toStringAsFixed(1)}, '
            'right=${padding.right.toStringAsFixed(1)}',
          );
          debugPrint(
            '📱 방향: ${isLandscape ? '가로(Landscape)' : '세로(Portrait)'}',
          );
        }

        final effectiveBgColor = bgColor;

        return Stack(
          children: [
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
                    return MidnightGoldBackground(baseColor: effectiveBgColor);
                  } else if (presetId == 'starlight_navy') {
                    return StarlightNavyBackground(baseColor: effectiveBgColor);
                  }
                  return ColoredBox(color: effectiveBgColor);
                },
              ),
            ),

            // Blur Effect (if image)
            if (bgType == 'image' && bgImagePath != null && bgBlur > 0)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: bgBlur, sigmaY: bgBlur),
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),

            // Dark Overlay for images to ensure readability
            if (bgType == 'image' && bgImagePath != null)
              Positioned.fill(
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.2)),
              ),

            PageView.builder(
              controller: _controller,
              physics: _disablePageSwipe
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: _hideRootPage ? _pageCount - 1 : _pageCount,
              onPageChanged: (index) {
                // ROOT 페이지 건너뛰기 위한 실제 인덱스 계산
                final actualIndex = _hideRootPage && index >= 5 ? index + 1 : index;
                setState(() {
                  _currentIndex = actualIndex;
                  _disablePageSwipe =
                      _pageKeys[actualIndex].currentState?.isEditMode ?? false;
                });
                if (_isRestoringIndex) return;
                // Fire-and-forget: a best-effort persistence.
                UserPrefService.setMainPageIndex(
                  accountName: widget.accountName,
                  index: actualIndex,
                );
              },
              itemBuilder: (context, index) {
                // ROOT 페이지(인덱스 5) 건너뛰기
                final actualIndex = _hideRootPage && index >= 5 ? index + 1 : index;
                return _IconGridPage(
                  key: _pageKeys[actualIndex],
                  accountName: widget.accountName,
                  pageIndex: actualIndex,
                  pageCount: _pageCount,
                  currentPage: _currentIndex,
                  pageController: _controller,
                  onRequestResetMainPages: _confirmAndResetMainPages,
                  onRequestQuickJump: _showQuickJumpSheet,
                  onRequestJumpToPage: (targetIndex) {
                    if (targetIndex < 0 || targetIndex >= _pageCount) return;
                    // ROOT 페이지 건너뛰기를 고려한 점프
                    final displayIndex = _hideRootPage && targetIndex > 5 
                        ? targetIndex - 1 
                        : (_hideRootPage && targetIndex == 5 ? -1 : targetIndex);
                    if (displayIndex < 0) return; // ROOT 페이지로 점프 시도 시 무시
                    _controller.animateToPage(
                      displayIndex,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  onEditModeChanged: (isEditMode) {
                    final displayIndex = _hideRootPage && actualIndex > 5 
                        ? actualIndex - 1 
                        : actualIndex;
                    if (displayIndex != _controller.page?.round()) return;
                    if (_disablePageSwipe == isEditMode) return;
                    setState(() => _disablePageSwipe = isEditMode);
                  },
                );
              },
            ),
            // Page quick-jump indicator (bottom center)
            if (_pageCount > 0)
              _buildPageLabel(context, isLandscape),
          ],
        );
      },
    );
  }

  Widget _buildPageLabel(BuildContext context, bool isLandscape) {
    return Positioned(
      left: 0,
      right: 0,
      top: isLandscape ? 4 : 12,
      child: SafeArea(
        bottom: false,
        child: Builder(
          builder: (context) {
            final showLabel =
                _currentIndex >= 0 &&
                _currentIndex < _pageNameLabels.length;
            if (!showLabel) return const SizedBox.shrink();
            final label = _pageNameLabels[_currentIndex];
            final scheme = Theme.of(context).colorScheme;

            return Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6.0,
                  horizontal: 16.0,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
