import 'package:flutter/foundation.dart';

/// A simple bridge to allow the FloatingVoiceButton to send text
/// to an active input screen (like QuickSimpleExpenseInputScreen).
class VoiceInputBridge {
  VoiceInputBridge._internal();
  static final VoiceInputBridge instance = VoiceInputBridge._internal();

  /// The text that should be placed into the input field.
  final ValueNotifier<String?> pendingInput = ValueNotifier<String?>(null);

  /// Requests the active screen to submit its data.
  final ValueNotifier<bool> requestSubmit = ValueNotifier<bool>(false);

  /// Sets the text and optionally requests submission.
  void sendInput(String text, {bool submit = false}) {
    pendingInput.value = text;
    if (submit) {
      requestSubmit.value = true;
    }
  }

  /// Clears the pending input after it has been consumed.
  void clear() {
    pendingInput.value = null;
    requestSubmit.value = false;
  }
}
