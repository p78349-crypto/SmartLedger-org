part of 'root_security_setup_screen.dart';

extension RootSecuritySetupScreenUi on _RootSecuritySetupScreenState {
  Widget _buildModeCard({
    required RootSecurityMode mode,
    required bool enabled,
    required bool configured,
    required void Function(bool)? onChanged,
    bool disabled = false,
    String? disabledReason,
  }) {
    final isActive = enabled && !disabled;

    return Card(
      elevation: isActive ? 4 : 2,
      color: disabled
          ? Colors.grey[200]
          : (isActive
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerLow),
      child: InkWell(
        onTap: disabled
            ? null
            : () {
                if (enabled) {
                  onChanged?.call(false);
                } else if (configured) {
                  onChanged?.call(true);
                } else {
                  // 설정 필요
                  if (mode == RootSecurityMode.pin) {
                    _setupPin();
                  } else if (mode == RootSecurityMode.password) {
                    _setupPassword();
                  } else {
                    onChanged?.call(true);
                  }
                }
              },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                mode.icon,
                size: 48,
                color: disabled
                    ? Colors.grey[400]
                    : (isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[600]),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          mode.displayName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: disabled ? Colors.grey[600] : null,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '사용중',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      disabled && disabledReason != null
                          ? disabledReason
                          : (!configured && !disabled
                                ? '${mode.description} (설정 필요)'
                                : mode.description),
                      style: TextStyle(
                        fontSize: 14,
                        color: disabled ? Colors.grey[600] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (disabled)
                Icon(Icons.block, color: Colors.grey[400], size: 32)
              else
                Checkbox(
                  value: enabled,
                  onChanged: onChanged == null
                      ? null
                      : (bool? value) => onChanged(value ?? false),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
