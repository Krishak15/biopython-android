import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ncbi_search_provider.dart';

class NcbiSearchResultsScreen extends StatelessWidget {
  const NcbiSearchResultsScreen({
    required this.results,
    required this.query,
    required this.db,
    super.key,
  });
  final List<Map<String, dynamic>> results;
  final String query;
  final String db;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => NcbiSearchProvider()..initialize(results),
    child: _NcbiSearchContent(query: query, db: db, allResults: results),
  );
}

class _NcbiSearchContent extends StatefulWidget {
  const _NcbiSearchContent({
    required this.query,
    required this.db,
    required this.allResults,
  });
  final String query;
  final String db;
  final List<Map<String, dynamic>> allResults;

  @override
  State<_NcbiSearchContent> createState() => _NcbiSearchContentState();
}

class _NcbiSearchContentState extends State<_NcbiSearchContent> {
  final _filterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filterController.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _filterController
      ..removeListener(_onFilterChanged)
      ..dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    if (!mounted) {
      return;
    }
    context.read<NcbiSearchProvider>().filterResults(
      widget.allResults,
      _filterController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<NcbiSearchProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Query: ${widget.query}'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            child: TextField(
              controller: _filterController,
              style: const TextStyle(fontFamily: 'Inter'),
              decoration: InputDecoration(
                hintText: 'Filter results...',
                prefixIcon: const Icon(Icons.filter_list_rounded),
                filled: true,
                fillColor: Colors.black, // surfaceContainerLowest
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerLow,
                ],
              ),
            ),
          ),
          if (provider.filteredResults.isEmpty)
            Center(
              child: Text(
                'Null ResultSet',
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: provider.filteredResults.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final res = provider.filteredResults[index];
                return InkWell(
                  onTap: () => context
                      .read<NcbiSearchProvider>()
                      .fetchAndAnalyze(context, res['id'], widget.db),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          res['title'] ?? 'Uncatalogued Record',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                res['id'],
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          if (provider.isFetching)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: const Center(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
