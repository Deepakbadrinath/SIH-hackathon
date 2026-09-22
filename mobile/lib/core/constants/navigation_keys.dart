import 'package:flutter/material.dart';

/// Global navigation and messaging keys ensuring reliable navigation and snackbars
/// from anywhere in the application (including overlay bars in MaterialApp.builder).
class NavigationKeys {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
}
