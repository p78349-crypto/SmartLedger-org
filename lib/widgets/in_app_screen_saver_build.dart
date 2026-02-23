part of 'in_app_screen_saver.dart';
// ignore_for_file: invalid_use_of_protected_member

extension InAppScreenSaverBuild on _InAppScreenSaverState {
  Widget _buildMain(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 820;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: Stack(
          children: [
            if (_backgroundPhotoPath != null)
              Positioned.fill(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    scheme.surface.withValues(alpha: 0.78),
                    BlendMode.srcATop,
                  ),
                  child: Image.file(
                    File(_backgroundPhotoPath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _tryDismissWithAuth,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _HeaderBar(title: widget.title, now: _now),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _error != null
                          ? _ErrorPanel(
                              message: _error!,
                              onRetry: _refreshData,
                            )
                          : (_data == null
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : isWide
                                ? Row(
                                    children: [
                                      SizedBox(
                                        width: 280,
                                        child: _LeftPanel(
                                          data: _data!,
                                          exposure: _exposure,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _CenterPanel(
                                          data: _data!,
                                          exposure: _exposure,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 280,
                                        child: _RightPanel(
                                          data: _data!,
                                          exposure: _exposure,
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView(
                                    children: [
                                      _CenterPanel(
                                        data: _data!,
                                        exposure: _exposure,
                                      ),
                                      const SizedBox(height: 12),
                                      _LeftPanel(
                                        data: _data!,
                                        exposure: _exposure,
                                      ),
                                      const SizedBox(height: 12),
                                      _RightPanel(
                                        data: _data!,
                                        exposure: _exposure,
                                      ),
                                    ],
                                  )),
                    ),
                    const SizedBox(height: 12),
                    _FooterBar(
                      authInProgress: _authInProgress,
                      onQuickReturn: _tryDismissWithAuth,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
