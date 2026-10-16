import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ui/discfit_widgets.dart';
import 'app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.clearHistory});
  final Future<bool> Function() clearHistory;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<String> _version = _loadVersion();
  bool _clearing = false;

  Future<String> _loadVersion() async {
    final project = await rootBundle.loadString('pubspec.yaml');
    final version = RegExp(r'^version:\s*(\S+)', multiLine: true)
        .firstMatch(project)
        ?.group(1);
    if (version == null) throw const FormatException('Project version missing');
    return version;
  }

  void _feedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _change(AppSettings settings,
      {ThemeMode? mode, bool? large}) async {
    final saved = await settings.update(mode: mode, large: large);
    _feedback(saved
        ? 'Settings saved.'
        : 'Could not save settings. Please try again.');
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              scrollable: true,
              title: const Text('Clear training history?'),
              content: const Text(
                  'This permanently deletes all scheduled and completed training sessions and resets progress and achievements. Your profile and settings will be kept.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Clear history')),
              ],
            ));
    if (confirmed != true || !mounted) return;
    setState(() => _clearing = true);
    final cleared = await widget.clearHistory();
    if (!mounted) return;
    setState(() => _clearing = false);
    _feedback(cleared
        ? 'Training history cleared. Progress and achievements reset.'
        : 'Could not clear training history. Please try again.');
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const PageHeading(
              'Make DiscFit yours', 'Choose how you train and view your app.'),
          if (settings.error != null) ...[
            Text(settings.error!),
            TextButton(
                onPressed: settings.busy ? null : settings.load,
                child: const Text('Retry loading settings')),
          ],
          SurfaceCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Appearance',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                    'System follows your device’s light or dark appearance.'),
                const SizedBox(height: 16),
                DropdownButtonFormField<ThemeMode>(
                  key: ValueKey(settings.themeMode),
                  initialValue: settings.themeMode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Color theme',
                      prefixIcon: Icon(Icons.palette_outlined)),
                  items: const [
                    DropdownMenuItem(
                        value: ThemeMode.system, child: Text('System')),
                    DropdownMenuItem(
                        value: ThemeMode.light, child: Text('Light')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark'))
                  ],
                  onChanged: settings.busy
                      ? null
                      : (mode) {
                          if (mode != null) _change(settings, mode: mode);
                        },
                ),
              ])),
          const SizedBox(height: 16),
          SurfaceCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Text size',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                    'Both sizes respect your device’s accessibility text size. Large adds 20%.'),
                const SizedBox(height: 16),
                DropdownButtonFormField<bool>(
                  key: ValueKey(settings.largeText),
                  initialValue: settings.largeText,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'Reading size',
                      prefixIcon: Icon(Icons.text_fields)),
                  items: const [
                    DropdownMenuItem(value: false, child: Text('Default')),
                    DropdownMenuItem(value: true, child: Text('Large'))
                  ],
                  onChanged: settings.busy
                      ? null
                      : (large) {
                          if (large != null) _change(settings, large: large);
                        },
                ),
              ])),
          const SizedBox(height: 16),
          SurfaceCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('About DiscFit',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                const Text('DiscFit',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                FutureBuilder<String>(
                    future: _version,
                    builder: (context, snapshot) => Text(snapshot.hasError
                        ? 'Version unavailable'
                        : 'Version ${snapshot.data ?? '…'}')),
                const SizedBox(height: 12),
                const Text(
                    'A frisbee training companion for students and beginner players. Learn drills, plan practice, and track progress through completed sessions.'),
              ])),
          const SizedBox(height: 16),
          SurfaceCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Training history',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                    'Delete all sessions and reset progress and achievements. Your profile and preferences stay saved.'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                    onPressed: _clearing ? null : _clear,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(
                        _clearing ? 'Clearing…' : 'Clear training history')),
              ])),
        ]),
      ))),
    );
  }
}
