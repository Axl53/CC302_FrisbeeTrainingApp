import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const FrisbeeApp());
}

const primaryColor = Color(0xff2b8553);
const darkGreen = Color(0xff173f32);
const borderColor = Color(0xffe1e9e4);

// STATELESS WIDGET: application and consistent theme.
class FrisbeeApp extends StatelessWidget {
  const FrisbeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiscFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
        ),
        scaffoldBackgroundColor: const Color(0xfff8f9f7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xfff8f9f7),
          foregroundColor: darkGreen,
          elevation: 0,
          centerTitle: false,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Color(0xff43574e),
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: darkGreen,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: borderColor),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const TrainingHome(),
    );
  }
}

// DATA MODEL: training drill.
class Drill {
  final String title;
  final String level;
  final int minutes;
  final String instructions;

  const Drill(
    this.title,
    this.level,
    this.minutes,
    this.instructions,
  );
}

const drills = [
  Drill(
    'Backhand Throw',
    'Beginner',
    15,
    '1. Warm up your wrists and shoulders.\n'
        '2. Hold the disc with your thumb on top.\n'
        '3. Stand sideways toward your partner.\n'
        '4. Step and release the disc flat.\n'
        '5. Practice 20 short throws, focusing on accuracy.',
  ),
  Drill(
    'Forehand Throw',
    'Beginner',
    15,
    '1. Place two fingers under the rim and your thumb on top.\n'
        '2. Keep your elbow close to your body.\n'
        '3. Flick your wrist while keeping the disc flat.\n'
        '4. Practice 20 short throws with a partner.',
  ),
  Drill(
    'Pancake Catch',
    'Beginner',
    10,
    '1. Stand facing your partner.\n'
        '2. Watch the disc as it approaches.\n'
        '3. Catch it between your hands, one above and one below.\n'
        '4. Complete 20 catches from a short distance.',
  ),
  Drill(
    'Pivot and Pass',
    'Intermediate',
    20,
    '1. Mark one foot as your pivot foot.\n'
        '2. Keep it in place while stepping with your other foot.\n'
        '3. Practice passes around a cone.\n'
        '4. Complete 10 passes on each side.',
  ),
  Drill(
    'Cutting and Footwork',
    'Intermediate',
    20,
    '1. Set up three cones in a zigzag.\n'
        '2. Jog toward a cone and change direction.\n'
        '3. Accelerate into open space for a pass.\n'
        '4. Repeat five times, resting between rounds.',
  ),
  Drill(
    'Long Throw Accuracy',
    'Advanced',
    25,
    '1. Warm up with short passes.\n'
        '2. Place a target cone 20 meters away.\n'
        '3. Throw toward the target using controlled power.\n'
        '4. Record accurate throws out of 10 attempts.\n'
        '5. Increase distance gradually.',
  ),
];

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
  const TrainingHome({super.key});

  @override
  State<TrainingHome> createState() => _TrainingHomeState();
}

class _TrainingHomeState extends State<TrainingHome> {
  int tab = 0;

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
                foregroundColor: Colors.red.shade700,
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
      'DiscFit',
      'Training Drills',
      'My Schedule',
      'My Profile',
      'My Progress',
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
              index: tab,
              children: [
                buildHome(),
                buildDrills(),
                buildSchedule(),
                const ProfileScreen(),
                buildProgress(),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: tab == 0,
        actions: [
          IconButton(
            tooltip: 'My progress',
            onPressed: () => setState(() => tab = 4),
            icon: const Icon(Icons.insights_outlined),
          ),
        ],
        title: Text(
          titles[tab],
          style: const TextStyle(
            fontSize: 26,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w900,
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
      floatingActionButton: !loading && loadError == null && tab == 2
          ? FloatingActionButton.extended(
              onPressed: saving ? null : () => editSession(),
              icon: const Icon(Icons.add),
              label: const Text('Add session'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: const Color(0xff718078),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
        onTap: (index) {
          setState(() => tab = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports),
            label: 'Drills',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Progress',
          ),
        ],
      ),
    );
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
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff121924)))),
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
        Container(
          constraints: const BoxConstraints(minHeight: 210),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff102c24), Color(0xff377553)]),
          ),
          child: Stack(children: [
            Positioned(
                right: -45,
                bottom: -35,
                child: Icon(Icons.sports_handball,
                    size: 235, color: Colors.white.withValues(alpha: 0.08))),
            Positioned(
                right: 12,
                top: 38,
                child: Transform.rotate(
                    angle: -0.35,
                    child: Image.asset('assets/frisbee.png', width: 145))),
            const Padding(
              padding: EdgeInsets.all(26),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Small Steps.\nLonger Throws.',
                        style: TextStyle(
                            fontSize: 30,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                            color: Colors.white)),
                    SizedBox(height: 18),
                    SizedBox(
                        width: 48,
                        child: Divider(color: Color(0xff87d48b), thickness: 4)),
                    SizedBox(height: 8),
                    Text('BETTER THROWS. A BRIGHTER GAME.',
                        style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.2,
                            color: Color(0xffd4e8da))),
                  ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        sectionTitle('Today\'s Training',
            onSeeAll: () => setState(() {
                  query = '';
                  level = 'All';
                  tab = 1;
                })),
        const SizedBox(height: 8),
        Material(
          color: const Color(0xffedf1eb),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openTraining(drills.first),
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Container(
                      width: 78,
                      height: 80,
                      decoration: BoxDecoration(
                          color: const Color(0xffd7e5d5),
                          borderRadius: BorderRadius.circular(12)),
                      child: Image.asset('assets/frisbee.png')),
                  const SizedBox(width: 16),
                  const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Backhand Basics',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xff121924))),
                        SizedBox(height: 8),
                        Text('Beginner  |  15 min',
                            style: TextStyle(fontSize: 13)),
                      ])),
                  const Icon(Icons.arrow_forward_rounded, color: darkGreen),
                ])),
          ),
        ),
        const SizedBox(height: 22),
        sectionTitle('Training Categories'),
        const SizedBox(height: 12),
        LayoutBuilder(
            builder: (context, constraints) => GridView.count(
                  crossAxisCount: constraints.maxWidth > 540 ? 6 : 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.94,
                  children: categories
                      .map((category) => Material(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: borderColor)),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                                onTap: () => setState(() {
                                      query = category.$3;
                                      level = 'All';
                                      tab = 1;
                                    }),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(category.$2,
                                          color: darkGreen, size: 36),
                                      const SizedBox(height: 10),
                                      Text(category.$1,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              height: 1.25,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xff121924))),
                                    ])),
                          ))
                      .toList(),
                )),
        const SizedBox(height: 20),
        FilledButton(
            onPressed: () => openTraining(drills.first),
            child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Start Training',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward),
                ])),
      ],
    );
  }

  Widget buildProgress() {
    final completed = sessions.where((session) => session.completed).toList();
    final minutes = completed.fold<int>(0, (total, session) {
      final matches = drills.where((drill) => drill.title == session.drill);
      return total + (matches.isEmpty ? 0 : matches.first.minutes);
    });
    return ListView(padding: const EdgeInsets.all(20), children: [
      sectionTitle('Your Training Journey'),
      const SizedBox(height: 16),
      InfoCard(
          title: 'Total Training Time',
          text: '${(minutes / 60).toStringAsFixed(1)} hours'),
      InfoCard(
          title: 'Completed Workouts', text: '${completed.length} sessions'),
      InfoCard(
          title: 'Session Completion',
          text: sessions.isEmpty
              ? 'Plan your first session to begin tracking progress.'
              : '${(completed.length / sessions.length * 100).round()}% of planned sessions'),
      const SizedBox(height: 16),
      sectionTitle('Achievements'),
      const SizedBox(height: 12),
      InfoCard(
          title:
              completed.isEmpty ? 'Your first workout awaits' : 'First Workout',
          text: completed.isEmpty
              ? 'Complete a scheduled practice to earn your first achievement.'
              : 'You took the first step. Keep showing up!'),
      const SizedBox(height: 20),
      const Text(
          'Progress isn\'t just longer throws.\nIt\'s a deeper love for the game.',
          textAlign: TextAlign.center,
          style: TextStyle(fontStyle: FontStyle.italic, fontSize: 17)),
      const SizedBox(height: 24),
      FilledButton.icon(
          onPressed: () => setState(() => tab = 2),
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Plan a training session')),
    ]);
  }

  Widget buildDrills() {
    final filtered = drills.where((drill) {
      final matchesSearch = drill.title.toLowerCase().contains(
            query.trim().toLowerCase(),
          );

      final matchesLevel = level == 'All' || drill.level == level;

      return matchesSearch && matchesLevel;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
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
                value: level,
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
        ),
        Expanded(
          child: filtered.isEmpty
              ? const MessageBox(
                  message: 'No matching drills. '
                      'Try another search or difficulty.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final drill = filtered[index];

                    return DrillCard(
                      drill: drill,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DrillDetails(drill: drill),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
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
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: borderColor),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(dateLabel(session.date)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: session.completed
                        ? const Color(0xffe8f4ed)
                        : const Color(0xfffff3db),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    session.completed ? 'Completed' : 'Planned',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: session.completed
                          ? darkGreen
                          : const Color(0xff785600),
                    ),
                  ),
                ),
                if (session.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(session.notes),
                ],
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
                        foregroundColor: const Color(0xffb34040),
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

// CUSTOM REUSABLE STATELESS WIDGET.
class InfoCard extends StatelessWidget {
  final String title;
  final String text;

  const InfoCard({
    super.key,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(text),
        ],
      ),
    );
  }
}

class DrillCard extends StatelessWidget {
  final Drill drill;
  final VoidCallback onTap;

  const DrillCard({
    super.key,
    required this.drill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = drill.level == 'Advanced'
        ? Icons.bolt
        : drill.level == 'Intermediate'
            ? Icons.directions_run
            : Icons.sports;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xffeaf4ee),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: primaryColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drill.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${drill.level} • ${drill.minutes} min',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xff718078),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MessageBox extends StatelessWidget {
  final String message;
  final VoidCallback? action;

  const MessageBox({
    super.key,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline,
              color: primaryColor,
              size: 40,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: action,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// NAVIGATION: opened when a drill card is tapped.
class DrillDetails extends StatelessWidget {
  final Drill drill;

  const DrillDetails({
    super.key,
    required this.drill,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(drill.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            InfoCard(
              title: drill.level,
              text: '${drill.minutes} minutes\n'
                  'Equipment: frisbee, partner, cones if needed',
            ),
            InfoCard(
              title: 'How to practice',
              text: drill.instructions,
            ),
            const SizedBox(height: 12),
            const Text(
              'Use Schedule to plan this drill and '
              'record your completed practice.',
            ),
          ],
        ),
      ),
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
              const Text(
                'Plan your practice',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a drill and a date that works for you.',
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: selectedDrill,
                isExpanded: true,
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
  const ProfileScreen({super.key});

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
        const Text(
          'Your player profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: darkGreen,
          ),
        ),
        const SizedBox(height: 6),
        const Text('Personalize your DiscFit training profile.'),
        const SizedBox(height: 20),
        Form(
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
                value: level,
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
        ),
        const SizedBox(height: 16),
        const Text(
          'Your profile is saved on this device.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
