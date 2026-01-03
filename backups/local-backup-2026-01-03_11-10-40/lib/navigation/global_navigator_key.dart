import 'package:flutter/material.dart';

/// Global key to keep the Navigator state (and thus the route stack)
/// alive across MaterialApp rebuilds (e.g. when theme changes).
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
