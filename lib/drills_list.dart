import 'package:flutter/material.dart';
import 'drill.dart';
import 'ui/training_cards.dart';

// Bundled drills remain available without an internet connection.
class DrillsList extends StatelessWidget {
  const DrillsList({super.key, required this.query, required this.level});
  final String query;
  final String level;

  @override
  Widget build(BuildContext context) {
    final filtered = drills
        .where((drill) =>
            drill.title.toLowerCase().contains(query.trim().toLowerCase()) &&
            (level == 'All' || drill.level == level))
        .toList();
    if (filtered.isEmpty) {
      return const MessageBox(
          message: 'No matching drills. Try another search or difficulty.');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => DrillCard(
          drill: filtered[index],
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => DrillDetails(drill: filtered[index])))),
    );
  }
}
