import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide theme mode, toggled from the Settings screen. Defaults to the
/// device setting until the user picks Light/Dark explicitly.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
