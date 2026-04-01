import 'package:flutter/material.dart';
import '../services/biology_platform_bridge.dart';
import '../screens/ncbi_search_results_screen.dart';

enum AnalysisStatus { idle, ready, processing, error }

class AnalysisHubProvider extends ChangeNotifier {
  final PythonImageBridge _bridge = PythonImageBridge();

  AnalysisStatus _status = AnalysisStatus.idle;
  AnalysisStatus get status => _status;

  String? _statusMessage;
  String? get statusMessage => _statusMessage;

  ProteinAnalysisResult? _proteinResult;
  ProteinAnalysisResult? get proteinResult => _proteinResult;

  String? _proteinError;
  String? get proteinError => _proteinError;

  DnaClassificationResult? _dnaResult;
  DnaClassificationResult? get dnaResult => _dnaResult;

  String? _dnaError;
  String? get dnaError => _dnaError;

  int _kmerSize = 3;
  int get kmerSize => _kmerSize;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  void setKmerSize(int value) {
    _kmerSize = value;
    notifyListeners();
  }

  Future<void> checkHealth() async {
    try {
      final health = await _bridge.healthBiology();
      final engineStatus = health['status'] as String? ?? 'IDLE';
      final error = health['error'] as String? ?? '';

      _status = engineStatus == 'READY'
          ? AnalysisStatus.ready
          : AnalysisStatus.idle;
      _statusMessage = error.isEmpty ? 'Genomic Engine Initialized' : error;
      notifyListeners();
    } catch (e) {
      _status = AnalysisStatus.error;
      _statusMessage = 'Engine Fault: $e';
      notifyListeners();
    }
  }

  Future<void> analyzeProtein(String sequence) async {
    if (sequence.isEmpty) {
      _proteinError = 'Sequence required';
      notifyListeners();
      return;
    }

    _status = AnalysisStatus.processing;
    _proteinResult = null;
    _proteinError = null;
    _statusMessage = 'Synthesizing protein structure...';
    notifyListeners();

    try {
      final result = await _bridge.analyzeProtein(sequence);
      _proteinResult = result;
      _proteinError = null;
      _status = AnalysisStatus.ready;
      _statusMessage = 'Protein diagnostics optimal.';
    } on BiologyBridgeException catch (e) {
      _proteinError = e.message;
      _status = AnalysisStatus.error;
      _statusMessage = 'Failure: ${e.message}';
    } catch (e) {
      _proteinError = 'Fault: $e';
      _status = AnalysisStatus.error;
      _statusMessage = 'Diagnostics error: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> classifyDna(String sequence) async {
    if (sequence.isEmpty) {
      _dnaError = 'Sequence required';
      notifyListeners();
      return;
    }

    _status = AnalysisStatus.processing;
    _dnaResult = null;
    _dnaError = null;
    _statusMessage = 'Sequence clustering engaged...';
    notifyListeners();

    try {
      final result = await _bridge.dnaClassify(sequence, kmerSize: _kmerSize);
      _dnaResult = result;
      _dnaError = null;
      _status = AnalysisStatus.ready;
      _statusMessage = 'Clustering complete. ${result.totalKmers} K-mers.';
    } on BiologyBridgeException catch (e) {
      _dnaError = e.message;
      _status = AnalysisStatus.error;
      _statusMessage = 'Classification fail: ${e.message}';
    } catch (e) {
      _dnaError = 'Fault: $e';
      _status = AnalysisStatus.error;
      _statusMessage = 'Classification error: $e';
    } finally {
      notifyListeners();
    }
  }

  void clearResults() {
    _proteinResult = null;
    _proteinError = null;
    _dnaResult = null;
    _status = AnalysisStatus.idle;
    _statusMessage = 'Awaiting input sequences.';
    notifyListeners();
  }

  Future<void> searchNCBI(BuildContext context, String query, String db) async {
    if (query.isEmpty) {
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final results = await _bridge.ncbiSearch(query, db: db);
      _isSearching = false;
      
      if (results.isEmpty) {
        _statusMessage = 'Repository null response.';
      } else {
        if (!context.mounted) {
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NcbiSearchResultsScreen(
              results: results,
              query: query,
              db: db,
            ),
          ),
        );
      }
    } catch (e) {
      _isSearching = false;
      _statusMessage = 'Query connection failed.';
    } finally {
      notifyListeners();
    }
  }
}
