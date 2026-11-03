import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

/// Coordinates the global cloud with the app-wide quick-action menu.
class AiGlobalCloudPresentation {
  AiGlobalCloudPresentation._();

  static final ValueNotifier<bool> isAddMenuOpen = ValueNotifier<bool>(false);
  static final ValueNotifier<int> chatOpenRequests = ValueNotifier<int>(0);
  static final ValueNotifier<Offset?> quickChatActionCenter =
      ValueNotifier<Offset?>(null);
  static VoidCallback? onQuickChatTap;

  static void requestOpenChat() {
    chatOpenRequests.value++;
  }
}
