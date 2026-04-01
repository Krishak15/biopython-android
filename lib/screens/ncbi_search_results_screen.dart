import 'package:flutter/material.dart';
import 'ncbi_record_details_screen.dart';
import '../services/biology_platform_bridge.dart';

class NcbiSearchResultsScreen extends StatefulWidget {
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
  State<NcbiSearchResultsScreen> createState() =>
      _NcbiSearchResultsScreenState();
}

class _NcbiSearchResultsScreenState extends State<NcbiSearchResultsScreen> {
  final _filterController = TextEditingController();
  late List<Map<String, dynamic>> _filteredResults;
  final _bridge = PythonImageBridge();
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _filteredResults = widget.results;
    _filterController.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _filterController..removeListener(_onFilterChanged)
    ..dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    final text = _filterController.text.toLowerCase();
    setState(() {
      _filteredResults = widget.results.where((res) {
        final title = (res['title'] as String? ?? '').toLowerCase();
        final id = (res['id'] as String? ?? '').toLowerCase();
        return title.contains(text) || id.contains(text);
      }).toList();
    });
  }

  Future<void> _fetchAndAnalyze(String id) async {
    setState(() => _isFetching = true);

    try {
      final record = await _bridge.ncbiFetch(id, db: widget.db);
      if (!mounted) {
        return;
      }
      setState(() => _isFetching = false);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NcbiRecordDetailsScreen(record: record),
        ),
      );
    } catch (e) {
      setState(() => _isFetching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection fault: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                colors: [theme.colorScheme.surface, theme.colorScheme.surfaceContainerLow],
              ),
            ),
          ),
          if (_filteredResults.isEmpty)
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
              itemCount: _filteredResults.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16), // spacing-6 separation
              itemBuilder: (context, index) {
                final res = _filteredResults[index];
                return InkWell(
                  onTap: () => _fetchAndAnalyze(res['id']),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20), // Between lg and xl
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          
          if (_isFetching)
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
