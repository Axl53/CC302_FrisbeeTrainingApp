import 'package:flutter/material.dart';
import '../drill.dart';
import 'discfit_widgets.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SurfaceCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700, color: accentColor(context))),
        const SizedBox(height: 10),
        Text(text),
      ])),
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
        color: surfaceColor(context),
        elevation: 1,
        shadowColor: const Color(0x15194c38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: edgeColor(context)),
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
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drill.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: accentColor(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        LabelBadge(drill.level,
                            warm: drill.level == 'Advanced'),
                        LabelBadge('${drill.minutes} min',
                            icon: Icons.schedule),
                      ]),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            Icon(
              Icons.info_outline,
              color: accentColor(context),
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
