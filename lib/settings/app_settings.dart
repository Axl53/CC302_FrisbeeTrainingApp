import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.system;
  bool largeText = false;
  bool busy = false;
  String? error;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (busy) return;
    busy = true;
    _notify();
    try {
      final preferences = await SharedPreferences.getInstance();
      final mode = preferences.getString('appearance');
      themeMode = ThemeMode.values.firstWhere((value) => value.name == mode,
          orElse: () => ThemeMode.system);
      largeText = preferences.getBool('largeText') ?? false;
      error = null;
    } catch (_) {
      error = 'Could not restore settings. Please retry.';
    }
    busy = false;
    _notify();
  }

  Future<bool> update({ThemeMode? mode, bool? large}) async {
    if (busy) return false;
    busy = true;
    _notify();
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = mode != null
          ? await preferences.setString('appearance', mode.name)
          : await preferences.setBool('largeText', large!);
      if (!saved) throw Exception('Settings save failed');
      if (mode != null) themeMode = mode;
      if (large != null) largeText = large;
      error = null;
      return true;
    } catch (_) {
      error = 'Could not save settings. Please try again.';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }
}

class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope(
      {super.key, required AppSettings settings, required super.child})
      : super(notifier: settings);

  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}

// Apply the user's multiplier to the device scaler instead of replacing it.
class PreferenceTextScaler extends TextScaler {
  const PreferenceTextScaler(this.device, this.multiplier);
  final TextScaler device;
  final double multiplier;

  @override
  double scale(double fontSize) => device.scale(fontSize) * multiplier;

  @override
  double get textScaleFactor => scale(14) / 14;
}
