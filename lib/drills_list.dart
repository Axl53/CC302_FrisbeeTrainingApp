import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'drill.dart';
import 'drills_api.dart';
import 'ui/training_cards.dart';

class DrillsList extends StatefulWidget {
  const DrillsList(
      {super.key, required this.query, required this.level, this.api});
  final String query;
  final String level;
  final DrillsApi? api;

  @override
  State<DrillsList> createState() => _DrillsListState();
}

class _DrillsListState extends State<DrillsList> {
  late final http.Client? _client;
  late final DrillsApi _api;
  List<Drill> _drills = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _client = widget.api == null ? http.Client() : null;
    _api = widget.api ?? DrillsApi(_client!);
    _load();
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final drills = await _api.fetch();
      if (mounted) setState(() => _drills = drills);
    } on TimeoutException {
      if (mounted) {
        setState(() => _error = 'Loading drills timed out. Please retry.');
      }
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'Could not load drills. Check your connection and retry.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(),
        SizedBox(height: 12),
        Text('Loading drills…')
      ])));
    }
    if (_error != null) return MessageBox(message: _error!, action: _load);
    if (_drills.isEmpty) {
      return MessageBox(
          message: 'No drills available yet. Please try again later.',
          action: _load);
    }
    final filtered = _drills
        .where((drill) =>
            drill.title
                .toLowerCase()
                .contains(widget.query.trim().toLowerCase()) &&
            (widget.level == 'All' || drill.level == widget.level))
        .toList();
    if (filtered.isEmpty) {
      return const MessageBox(
          message: 'No matching drills. Try another search or difficulty.');
    }
    return Column(children: [
      Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh drills'))),
      Expanded(
          child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) => DrillCard(
                    drill: filtered[index],
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) =>
                                DrillDetails(drill: filtered[index])))),
              ))),
    ]);
  }
}
