import 'package:flutter/material.dart';
import '../services/biology_platform_bridge.dart';
import '../screens/ncbi_record_details_screen.dart';
import '../providers/analysis_hub_provider.dart';
import 'package:provider/provider.dart';

class NcbiSearchProvider extends ChangeNotifier {
  final PythonImageBridge _bridge = PythonImageBridge();

  bool _isFetching = false;
  bool get isFetching => _isFetching;

  List<Map<String, dynamic>> _filteredResults = [];
  List<Map<String, dynamic>> get filteredResults => _filteredResults;

  void initialize(List<Map<String, dynamic>> initialResults) {
    _filteredResults = initialResults;
  }

  void filterResults(List<Map<String, dynamic>> allResults, String filterText) {
    final text = filterText.toLowerCase();
    _filteredResults = allResults.where((res) {
      final title = (res['title'] as String? ?? '').toLowerCase();
      final id = (res['id'] as String? ?? '').toLowerCase();
      return title.contains(text) || id.contains(text);
    }).toList();
    notifyListeners();
  }

  Future<void> fetchAndAnalyze(BuildContext context, String id, String db) async {
    _isFetching = true;
    notifyListeners();

    try {
      // Respect the global sequence limit and identity from AnalysisHubProvider
      final hub = Provider.of<AnalysisHubProvider>(context, listen: false);
      final limit = hub.maxSequenceLength;
      final email = hub.userEmail;
      final apiKey = hub.ncbiApiKey;

      final record = await _bridge.ncbiFetch(id,
          db: db, limit: limit, email: email, apiKey: apiKey);
      _isFetching = false;
      
      if (!context.mounted) {
        return;
      }
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NcbiRecordDetailsScreen(record: record),
        ),
      );
    } catch (e) {
      _isFetching = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection fault: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      notifyListeners();
    }
  }
}
