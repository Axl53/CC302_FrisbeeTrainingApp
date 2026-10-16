import 'dart:convert';
import 'settings/app_settings.dart';
import 'settings/settings_screen.dart';
import 'ui/app_theme.dart';
import 'ui/disc_photo.dart';
import 'drill.dart';
import 'drills_list.dart';
import 'drills_api.dart';
import 'ui/discfit_widgets.dart';
import 'ui/training_cards.dart';
export 'ui/training_cards.dart';
export 'drill.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const FrisbeeApp());
}

const primaryColor = forest;
const darkGreen = Color(0xff173f32);
const borderColor = Color(0xffe1e9e4);

// App-wide preferences live above the Navigator so every route updates immediately.
class FrisbeeApp extends StatefulWidget {
  const FrisbeeApp({super.key, this.drillsApi});
  final DrillsApi? drillsApi;

  @override
  State<FrisbeeApp> createState() => _FrisbeeAppState();
}

class _FrisbeeAppState extends State<FrisbeeApp> {
  final settings = AppSettings();
  bool ready = false;

  @override
  void initState() {
    super.initState();
    settings.load().then((_) {
      if (mounted) setState(() => ready = true);
    });
  }

  @override
  void dispose() {
    settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SettingsScope(
        settings: settings,
        child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) => MaterialApp(
                  title: 'DiscFit',
                  debugShowCheckedModeBanner: false,
                  theme: discFitTheme(Brightness.light),
                  darkTheme: discFitTheme(Brightness.dark),
                  themeMode: settings.themeMode,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                        textScaler: PreferenceTextScaler(
                            MediaQuery.textScalerOf(context),
                            settings.largeText ? 1.2 : 1)),
                    child: child!,
                  ),
                  home: ready
                      ? TrainingHome(drillsApi: widget.drillsApi)
                      : const Scaffold(
                          body: Center(child: CircularProgressIndicator())),
                )),
      );
}

// DATA MODEL: a scheduled training session.
class Session {
  final String id;
  final String drill;
  final String notes;
  final DateTime date;
  final bool completed;

  const Session({
    required this.id,
    required this.drill,
    required this.date,
    this.notes = '',
    this.completed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'drill': drill,
      'date': date.toIso8601String(),
      'notes': notes,
      'completed': completed,
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      drill: json['drill'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String,
      completed: json['completed'] as bool,
    );
  }

  Session toggle() {
    return Session(
      id: id,
      drill: drill,
      date: date,
      notes: notes,
      completed: !completed,
    );
  }
}

String dateLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

// STATEFUL WIDGET: navigation, sessions, search and progress.
class TrainingHome extends StatefulWidget {
  const TrainingHome({super.key, this.drillsApi});
  final DrillsApi? drillsApi;

  @override
  State<TrainingHome> createState() => _TrainingHomeState();
}

class _TrainingHomeState extends State<TrainingHome> {
  AppTab tab = AppTab.home;

  final searchController = TextEditingController();
  String query = '';
  String level = 'All';

  bool loading = true;
  bool saving = false;

  String? loadError;

  List<Session> sessions = [];

  @override
  void initState() {
    super.initState();
    loadSessions();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Load saved sessions from the device.
  Future<void> loadSessions() async {
    setState(() {
      loading = true;
      loadError = null;
    });

    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString('sessions');

      final items = raw == null
          ? <Session>[]
          : (jsonDecode(raw) as List).map((item) {
              return Session.fromJson(
                Map<String, dynamic>.from(item as Map),
              );
            }).toList();

      if (!mounted) return;

      setState(() {
        sessions = items;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        loadError = 'Could not load your saved sessions. Please retry.';
      });
    }
  }

  void showFeedback(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Save changes before updating the displayed list.
  Future<void> saveSessions(
    List<Session> updated,
    String message,
  ) async {
    if (saving) return;

    setState(() => saving = true);

    try {
      final preferences = await SharedPreferences.getInstance();

      final successful = await preferences.setString(
        'sessions',
        jsonEncode(
          updated.map((session) => session.toJson()).toList(),
        ),
      );

      if (!successful) {
        throw Exception('Save failed');
      }

      if (!mounted) return;

      setState(() => sessions = updated);
      showFeedback(message);
    } catch (_) {
      showFeedback('Could not save changes. Please try again.');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  // Navigate to the add/edit form and receive its result.
  Future<void> editSession([Session? oldSession]) async {
    final result = await Navigator.push<Session>(
      context,
      MaterialPageRoute(
        builder: (_) => SessionForm(session: oldSession),
      ),
    );

    if (result == null || !mounted) return;

    final updated = [...sessions];
    final index = updated.indexWhere(
      (session) => session.id == result.id,
    );

    if (index < 0) {
      updated.add(result);
    } else {
      updated[index] = result;
    }

    await saveSessions(
      updated,
      oldSession == null
          ? 'Training session added.'
          : 'Training session updated.',
    );
  }

  // DELETE FUNCTIONALITY with confirmation.
  Future<void> deleteSession(Session session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete session?'),
          content: Text(
            'Delete ${session.drill} on ${dateLabel(session.date)}? '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await saveSessions(
      sessions.where((item) => item.id != session.id).toList(),
      'Session deleted.',
    );
  }

  @override
  Widget build(BuildContext context) {
    const titles = [
      'Training Drills',
      'My Schedule',
      'DiscFit',
      'My Progress',
      'My Profile',
    ];

    Widget content;

    if (loading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (loadError != null) {
      content = MessageBox(
        message: loadError!,
        action: loadSessions,
      );
    } else {
      content = Column(
        children: [
          if (saving) const LinearProgressIndicator(),
          Expanded(
            child: IndexedStack(
              index: tab.index,
              children: [
                buildDrills(),
                buildSchedule(),
                buildHome(),
                buildProgress(),
                ProfileScreen(onSettings: openSettings),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: tab == AppTab.home,
        actions: [
          if (tab == AppTab.home)
            IconButton(
                tooltip: 'Settings',
                onPressed: openSettings,
                icon: const Icon(Icons.settings_outlined)),
          IconButton(
            tooltip: 'My progress',
            onPressed: () => setState(() => tab = AppTab.progress),
            icon: const Icon(Icons.insights_outlined),
          ),
        ],
        title: Text(
          titles[tab.index],
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: content,
          ),
        ),
      ),
      floatingActionButton:
          !loading && loadError == null && tab == AppTab.schedule
              ? FloatingActionButton.extended(
                  onPressed: saving ? null : () => editSession(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add session'),
                )
              : null,
      bottomNavigationBar: DiscFitNavigation(
        selected: tab,
        onSelect: (destination) => setState(() => tab = destination),
      ),
    );
  }

  void openSettings() {
    Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) =>
                SettingsScreen(clearHistory: clearTrainingHistory)));
  }

  Future<bool> clearTrainingHistory() async {
    if (saving) return false;
    setState(() => saving = true);
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.setString('sessions', '[]')) return false;
      if (!mounted) return false;
      setState(() => sessions = []);
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void openTraining(Drill drill) {
    Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => DrillDetails(drill: drill),
        ));
  }

  Widget sectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Row(children: [
      Expanded(
          child: Text(title,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface))),
      if (onSeeAll != null)
        TextButton(onPressed: onSeeAll, child: const Text('See All')),
    ]);
  }

  Widget buildHome() {
    const categories = [
      ('Throwing\nTechnique', Icons.sports, 'Throw'),
      ('Accuracy\nDrills', Icons.track_changes, 'Accuracy'),
      ('Footwork &\nMovement', Icons.directions_run, 'Footwork'),
      ('Catching\nSkills', Icons.back_hand_outlined, 'Catch'),
      ('Pivot &\nMovement', Icons.accessibility_new, 'Pivot'),
      ('All\nTraining', Icons.grid_view_rounded, ''),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const PageHeading('Ready for a little progress?',
            'Your next great throw starts here.'),
        const TrainingHero(),
        const SizedBox(height: 24),
        sectionTitle('Today\'s Training',
            onSeeAll: () => setState(() {
                  query = '';
                  searchController.clear();
                  level = 'All';
                  tab = AppTab.drills;
                })),
        const SizedBox(height: 8),
        Material(
          color: softColor(context),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openTraining(drills.first),
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  const DiscPhoto(
                      width: 78, height: 80, fit: BoxFit.cover, radius: 12),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Backhand Basics',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 8),
                        const Text('Beginner  |  15 min',
                            style: TextStyle(fontSize: 13)),
                      ])),
                  Icon(Icons.arrow_forward_rounded,
                      color: accentColor(context)),
                ])),
          ),
        ),
        const SizedBox(height: 22),
        sectionTitle('Training Categories'),
        const SizedBox(height: 12),
        ResponsiveTiles(
            minWidth: 105,
            children: categories
                .map((category) => Material(
                      color: surfaceColor(context),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: edgeColor(context))),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => setState(() {
                          query = category.$3;
                          searchController.text = query;
                          level = 'All';
                          tab = AppTab.drills;
                        }),
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(children: [
                              Icon(category.$2,
                                  color: accentColor(context), size: 28),
                              const SizedBox(height: 12),
                              Text(category.$1.replaceAll('\n', ' '),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ])),
                      ),
                    ))
                .toList()),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => openTraining(drills.first),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Start Training'),
        ),
        const SizedBox(height: 24),
        sectionTitle('Make it a habit'),
        const SizedBox(height: 12),
        ResponsiveTiles(children: [
          OutlinedButton.icon(
              onPressed: saving ? null : () => editSession(),
              icon: const Icon(Icons.add),
              label: const Text('Plan practice')),
          OutlinedButton.icon(
              onPressed: () => setState(() => tab = AppTab.progress),
              icon: const Icon(Icons.insights),
              label: const Text('View progress')),
        ]),
      ],
    );
  }

  Widget buildProgress() {
    final completed = sessions.where((session) => session.completed).toList();
    final minutes = completed.fold<int>(0, (total, session) {
      final matches = drills.where((drill) => drill.title == session.drill);
      return total + (matches.isEmpty ? 0 : matches.first.minutes);
    });
    final ratio = sessions.isEmpty ? 0.0 : completed.length / sessions.length;
    return ListView(padding: const EdgeInsets.all(20), children: [
      const PageHeading(
          'Your Training Journey', 'Every completed practice counts.'),
      ResponsiveTiles(children: [
        StatTile(
            value: '${(minutes / 60).toStringAsFixed(1)} hours',
            label: 'Total Training Time',
            icon: Icons.timer_outlined),
        StatTile(
            value: '${completed.length} sessions',
            label: 'Completed Workouts',
            icon: Icons.task_alt),
        StatTile(
            value: '${sessions.length}',
            label: 'Planned sessions',
            icon: Icons.calendar_month_outlined),
      ]),
      const SizedBox(height: 20),
      SurfaceCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        sectionTitle('Session Completion'),
        const SizedBox(height: 12),
        Text(sessions.isEmpty
            ? 'Plan your first session to begin tracking progress.'
            : '${(ratio * 100).round()}% of planned sessions'),
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: ratio),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 450),
          builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
              semanticsLabel: 'Session completion',
              semanticsValue: '${(ratio * 100).round()}%'),
        ),
        const SizedBox(height: 12),
        Text('${completed.length} of ${sessions.length} sessions completed'),
      ])),
      const SizedBox(height: 24),
      sectionTitle('Achievements'),
      const SizedBox(height: 12),
      SurfaceCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(
            completed.isEmpty
                ? Icons.emoji_events_outlined
                : Icons.emoji_events,
            size: 32,
            color: accentColor(context)),
        const SizedBox(height: 12),
        Text(completed.isEmpty ? 'Your first workout awaits' : 'First Workout',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(completed.isEmpty
            ? 'Complete a scheduled practice to earn your first achievement.'
            : 'You completed your first practice. Keep showing up!'),
        if (completed.length >= 5) ...[
          const SizedBox(height: 16),
          const LabelBadge('Five practices completed',
              icon: Icons.verified_outlined)
        ],
        if (minutes >= 60) ...[
          const SizedBox(height: 12),
          const LabelBadge('One hour of practice', icon: Icons.timer_outlined)
        ],
      ])),
      const SizedBox(height: 24),
      FilledButton.icon(
          onPressed: () => setState(() => tab = AppTab.schedule),
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Plan a training session')),
    ]);
  }

  Widget buildDrills() {
    return LayoutBuilder(
        builder: (context, constraints) => Column(
              children: [
                ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: constraints.maxHeight * 0.52),
                    child: SingleChildScrollView(
                        child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: searchController,
                            onChanged: (value) {
                              setState(() => query = value);
                            },
                            decoration: const InputDecoration(
                              labelText: 'Search drills',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey('difficulty-$level'),
                            isExpanded: true,
                            initialValue: level,
                            decoration: const InputDecoration(
                              labelText: 'Difficulty',
                            ),
                            items: [
                              'All',
                              'Beginner',
                              'Intermediate',
                              'Advanced',
                            ].map((value) {
                              return DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => level = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ))),
                Expanded(
                  child: tab == AppTab.drills
                      ? DrillsList(
                          query: query, level: level, api: widget.drillsApi)
                      : const SizedBox.shrink(),
                ),
              ],
            ));
  }

  Widget buildSchedule() {
    final sorted = [...sessions]..sort((a, b) => a.date.compareTo(b.date));

    if (sorted.isEmpty) {
      return const MessageBox(
        message: 'No training sessions yet.\n'
            'Tap Add session to plan your first practice.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final session = sorted[index];

        return Card(
          elevation: 1,
          shadowColor: const Color(0x10194c38),
          color: surfaceColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: edgeColor(context)),
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.drill,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: accentColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                LabelBadge(dateLabel(session.date),
                    icon: Icons.calendar_today_outlined),
                const SizedBox(height: 8),
                LabelBadge(session.completed ? 'Completed' : 'Planned',
                    icon: session.completed ? Icons.task_alt : Icons.schedule,
                    warm: !session.completed),
                if (session.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(session.notes),
                ],
                const SizedBox(height: 16),
                Divider(height: 1, color: edgeColor(context)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: saving
                          ? null
                          : () {
                              saveSessions(
                                sessions.map((item) {
                                  return item.id == session.id
                                      ? item.toggle()
                                      : item;
                                }).toList(),
                                session.completed
                                    ? 'Marked as planned.'
                                    : 'Training completed.',
                              );
                            },
                      icon: Icon(
                        session.completed ? Icons.undo : Icons.check,
                      ),
                      label: Text(
                        session.completed ? 'Undo complete' : 'Complete',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: saving ? null : () => editSession(session),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: saving ? null : () => deleteSession(session),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// FORM: add or edit a session.
class SessionForm extends StatefulWidget {
  final Session? session;

  const SessionForm({
    super.key,
    this.session,
  });

  @override
  State<SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends State<SessionForm> {
  final formKey = GlobalKey<FormState>();

  late String selectedDrill;
  late DateTime selectedDate;
  late TextEditingController notesController;

  @override
  void initState() {
    super.initState();

    selectedDrill = widget.session?.drill ?? drills.first.title;
    selectedDate = widget.session?.date ?? DateTime.now();

    notesController = TextEditingController(
      text: widget.session?.notes ?? '',
    );
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 10),
    );

    if (result != null && mounted) {
      setState(() => selectedDate = result);
    }
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;

    final session = Session(
      id: widget.session?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      drill: selectedDrill,
      date: selectedDate,
      notes: notesController.text.trim(),
      completed: widget.session?.completed ?? false,
    );

    Navigator.pop(context, session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.session == null
              ? 'Add Training Session'
              : 'Edit Training Session',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Plan your practice',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: accentColor(context),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a drill and a date that works for you.',
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: selectedDrill,
                decoration: const InputDecoration(
                  labelText: 'Training drill',
                ),
                items: drills.map((drill) {
                  return DropdownMenuItem(
                    value: drill.title,
                    child: Text(drill.title),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedDrill = value);
                  }
                },
                validator: (value) {
                  return value == null ? 'Choose a drill.' : null;
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: selectDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  'Date: ${dateLabel(selectedDate)}',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: notesController,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Example: 20 throws with a partner',
                ),
                validator: (value) {
                  if ((value?.trim().length ?? 0) > 200) {
                    return 'Keep notes within 200 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: submit,
                icon: const Icon(Icons.check),
                label: const Text('Save session'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Profile details are saved locally on this device.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onSettings});
  final VoidCallback? onSettings;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  static const levels = ['Beginner', 'Intermediate', 'Advanced'];
  String level = 'Beginner';
  bool loading = true;
  bool saving = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    setState(() {
      loading = true;
      loadError = null;
    });
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString('profile');
      final profile = raw == null
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        nameController.text = profile['name'] as String? ?? '';
        locationController.text = profile['location'] as String? ?? '';
        level = levels.contains(profile['level'])
            ? profile['level'] as String
            : 'Beginner';
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadError = 'Could not load your profile. Please retry.';
      });
    }
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        'profile',
        jsonEncode({
          'name': nameController.text.trim(),
          'location': locationController.text.trim(),
          'level': level,
        }),
      );
      if (!saved) throw Exception('Profile save failed.');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not save your profile. Please retry.')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (loadError != null) {
      return MessageBox(message: loadError!, action: loadProfile);
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: darkGreen,
            child: Icon(Icons.person, color: Colors.white, size: 48),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Your player profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: accentColor(context),
          ),
        ),
        const SizedBox(height: 6),
        const Text('Make it yours. Your details stay on this device.'),
        const SizedBox(height: 20),
        SurfaceCard(
            child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                enabled: !saving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter your name.'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: level,
                decoration: const InputDecoration(
                  labelText: 'Skill level',
                  prefixIcon: Icon(Icons.sports),
                ),
                items: levels
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                onChanged: saving
                    ? null
                    : (value) {
                        if (value != null) setState(() => level = value);
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: locationController,
                enabled: !saving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Training location (optional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: saving ? null : saveProfile,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Saving...' : 'Save profile'),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 16),
        if (widget.onSettings != null) ...[
          SurfaceCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                subtitle: const Text('Appearance, text size and history'),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onSettings,
              )),
          const SizedBox(height: 16),
        ],
        const Text(
          'Your profile is saved on this device.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
