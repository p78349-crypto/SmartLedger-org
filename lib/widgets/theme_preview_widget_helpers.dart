part of theme_preview_widget;

extension _ThemePreviewWidgetBuilders on _ThemePreviewWidgetState {
  Widget _buildIconCard(String asset) {
    return SizedBox(
      width: 96,
      height: 112,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: ThemeService.instance,
            builder: (context, _) {
              final current = ThemeService.instance.current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: current.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: SvgPicture.asset(
                    asset,
                    width: 44,
                    height: 44,
                    colorFilter: ColorFilter.mode(
                      current.onColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text('Sample', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _variantButton(BuildContext context, ThemeVariant v) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          ThemeService.instance.preview(v);
        },
        child: AnimatedBuilder(
          animation: ThemeService.instance,
          builder: (context, _) {
            final current = ThemeService.instance.current;
            final isSelected = current.id == v.id;
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: v.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Image.asset(
                      ThemeService.instance.wallpaperAssetFor(v),
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    v.name,
                    style: TextStyle(color: v.onColor, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
