import 'package:flutter/material.dart';
import 'ncbi_record_details_screen.dart';
import '../services/biology_bridge_exception.dart';

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
    _filterController
      ..removeListener(_onFilterChanged)
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
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Search: ${widget.query}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: TextField(
              controller: _filterController,
              decoration: InputDecoration(
                hintText: 'Filter results locally...',
                prefixIcon: const Icon(Icons.filter_list),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
          if (_filteredResults.isEmpty)
            const Center(child: Text('No matching results found.'))
          else
            ListView.builder(
              itemCount: _filteredResults.length,
              itemBuilder: (context, index) {
                final res = _filteredResults[index];
                return ListTile(
                  title: Text(
                    res['title'] ?? 'No Title',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('ID: ${res['id']} | DB: ${widget.db}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _fetchAndAnalyze(res['id']),
                );
              },
            ),
          if (_isFetching)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
