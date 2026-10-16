import 'package:flutter/material.dart';
import 'disc_photo.dart';

const forest = Color(0xff194c38);
const canvas = Color(0xfff6f7f2);
const outline = Color(0xffe1e7de);

Color accentColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.primary
        : forest;
Color surfaceColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surfaceContainer
        : Colors.white;
Color edgeColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.outlineVariant
        : outline;
Color softColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : const Color(0xffedf1eb);

// Named destinations keep quick actions and the bottom bar in sync.
enum AppTab { drills, schedule, home, progress, profile }

class SurfaceCard extends StatelessWidget {
  const SurfaceCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: surfaceColor(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: edgeColor(context)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x07194c38), blurRadius: 18, offset: Offset(0, 6))
          ],
        ),
        child: Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: child),
      );
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: accentColor(context))),
          const SizedBox(height: 6),
          Text(subtitle),
        ]),
      );
}

class LabelBadge extends StatelessWidget {
  const LabelBadge(this.label, {super.key, this.icon, this.warm = false});
  final String label;
  final IconData? icon;
  final bool warm;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: warm
                ? Theme.of(context).colorScheme.tertiaryContainer
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon,
                size: 16,
                color: warm
                    ? Theme.of(context).colorScheme.onTertiaryContainer
                    : Theme.of(context).colorScheme.onPrimaryContainer),
            const SizedBox(width: 6)
          ],
          Flexible(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: warm
                          ? Theme.of(context).colorScheme.onTertiaryContainer
                          : Theme.of(context).colorScheme.onPrimaryContainer))),
        ]),
      );
}

class StatTile extends StatelessWidget {
  const StatTile(
      {super.key,
      required this.value,
      required this.label,
      required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SurfaceCard(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor(context)),
          const SizedBox(height: 14),
          Text(value,
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: accentColor(context))),
          const SizedBox(height: 4),
          Text(label),
        ],
      ));
}

class ResponsiveTiles extends StatelessWidget {
  const ResponsiveTiles(
      {super.key, required this.children, this.minWidth = 145});
  final List<Widget> children;
  final double minWidth;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final count =
            (constraints.maxWidth / (minWidth * scale)).floor().clamp(1, 3);
        final width = (constraints.maxWidth - (count - 1) * 12) / count;
        return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: children
                .map((child) => SizedBox(width: width, child: child))
                .toList());
      });
}

class DiscFitNavigation extends StatelessWidget {
  const DiscFitNavigation(
      {super.key, required this.selected, required this.onSelect});
  final AppTab selected;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    const labels = ['Drills', 'Schedule', 'Home', 'Progress', 'Profile'];
    const icons = [
      Icons.sports_outlined,
      Icons.calendar_month_outlined,
      Icons.home_rounded,
      Icons.insights_outlined,
      Icons.person_outline_rounded
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
          color: surfaceColor(context),
          border: Border(top: BorderSide(color: edgeColor(context)))),
      child: SafeArea(
          top: false,
          child: Padding(
            // Elevation is contained inside the bar, so it never covers content.
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: AppTab.values.map((tab) {
                  final active = selected == tab;
                  final home = tab == AppTab.home;
                  return Expanded(
                      child: Semantics(
                    selected: active,
                    button: true,
                    excludeSemantics: true,
                    onTap: () => onSelect(tab),
                    label: labels[tab.index],
                    child: Tooltip(
                        message: labels[tab.index],
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => onSelect(tab),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: MediaQuery.disableAnimationsOf(
                                              context)
                                          ? Duration.zero
                                          : const Duration(milliseconds: 180),
                                      width: home ? 48 : 44,
                                      height: home ? 48 : 44,
                                      transform: Matrix4.translationValues(
                                          0, home ? -5 : 0, 0),
                                      decoration: BoxDecoration(
                                        color: home
                                            ? forest
                                            : active
                                                ? const Color(0xffe6f0e6)
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                            home ? 28 : 14),
                                        boxShadow: home
                                            ? [
                                                const BoxShadow(
                                                    color: Color(0x25194c38),
                                                    blurRadius: 10,
                                                    offset: Offset(0, 4))
                                              ]
                                            : [],
                                        border: home && active
                                            ? Border.all(
                                                color: const Color(0xff9ac69b),
                                                width: 3)
                                            : null,
                                      ),
                                      child: Icon(icons[tab.index],
                                          color: home
                                              ? Colors.white
                                              : active
                                                  ? forest
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(labels[tab.index],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: active
                                                ? accentColor(context)
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                            fontWeight: active
                                                ? FontWeight.w800
                                                : FontWeight.w500)),
                                    const SizedBox(height: 4),
                                    Container(
                                        width: 16,
                                        height: 3,
                                        decoration: BoxDecoration(
                                            color: active
                                                ? accentColor(context)
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(3))),
                                  ])),
                        )),
                  ));
                }).toList()),
          )),
    );
  }
}

class TrainingHero extends StatelessWidget {
  const TrainingHero({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff143e2e), Color(0xff347451)])),
        child: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 400 ||
              MediaQuery.textScalerOf(context).scale(16) > 21;
          const text =
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('MAKE TIME TO PLAY',
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.4,
                    color: Color(0xffc9e1c2),
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 14),
            Text('Small steps.\nLonger throws.',
                style: TextStyle(
                    fontSize: 30,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            SizedBox(height: 14),
            Text('Build your skills, one practice at a time.',
                style: TextStyle(color: Color(0xffe0ecdf))),
          ]);
          final photoWidth = compact
              ? constraints.maxWidth.clamp(0.0, 360.0).toDouble()
              : 180.0;
          final image = ExcludeSemantics(
              child: DiscPhoto(
                  width: photoWidth,
                  height: photoWidth * 414 / 708,
                  fit: BoxFit.contain,
                  radius: 18));
          return compact
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  text,
                  const SizedBox(height: 16),
                  Align(alignment: Alignment.centerRight, child: image)
                ])
              : Row(children: [
                  const Expanded(child: text),
                  const SizedBox(width: 12),
                  image
                ]);
        }),
      );
}
