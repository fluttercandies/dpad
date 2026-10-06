import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

import '../data.dart';
import '../widgets/poster_card.dart';

/// Demonstrates that d-pad navigation and text input coexist: while the
/// field is being edited, arrows move the caret and app shortcuts stand
/// down; the moment focus moves on, the remote drives the grid again.
class SearchSection extends StatefulWidget {
  const SearchSection({super.key});

  @override
  State<SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends State<SearchSection> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase();
    final results = [
      for (final row in homeRows)
        for (final movie in row.movies)
          if (query.isEmpty || movie.title.toLowerCase().contains(query)) movie,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 32, 36, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 480,
            child: TextField(
              controller: _controller,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search titles…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white.withAlpha(15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'While typing, arrows move the caret — at the edges of the text '
            '(and with ↓) they leave the field. You are never trapped.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Text(
            '${results.length} title${results.length == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DpadRegion(
              debugLabel: 'search-results',
              memoryKey: 'search-results',
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 260,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 16,
                  childAspectRatio: 240 / 124,
                ),
                itemCount: results.length,
                itemBuilder: (context, index) => PosterCard(
                  movie: results[index],
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
