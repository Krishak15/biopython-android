import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ncbi_search_provider.dart';
import '../theme/app_theme.dart';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Repository Results'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'QUERY: ${widget.query.toUpperCase()}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.tertiary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'DB: ${widget.db.toUpperCase()}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _filterController,
                  decoration: InputDecoration(
                    hintText: 'Filter results...',
                    prefixIcon: const Icon(Icons.filter_list_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: provider.filteredResults.isEmpty
                ? Center(
                    child: Text(
                      'Null ResultSet',
                      style: theme.textTheme.labelLarge?.copyWith(
                        letterSpacing: 2,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    itemCount: provider.filteredResults.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final res = provider.filteredResults[index];
                      return _RepositoryCard(
                        theme: theme,
                        id: res['id'],
                        title: res['title'] ?? 'Uncatalogued Record',
                        onTap: () => context
                            .read<NcbiSearchProvider>()
                            .fetchAndAnalyze(context, res['id'], widget.db),
                      );
                    },
                  ),
          ),
          if (provider.isFetching)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tertiary),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'FETCHING ACCESSION...',
                      style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.tertiary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RepositoryCard extends StatelessWidget {
  const _RepositoryCard({
    required this.theme,
    required this.id,
    required this.title,
    required this.onTap,
  });

  final ThemeData theme;
  final String id;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 10),
                          const SizedBox(width: 6),
                          Text(
                            'MATCH FOUND',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.greenAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      id,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: AppTheme.tertiary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                     Text(
                      'DECODE RECORD',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
