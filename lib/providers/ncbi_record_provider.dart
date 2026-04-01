import 'package:flutter/material.dart';
import '../services/biology_platform_bridge.dart';

class NcbiRecordProvider extends ChangeNotifier {
  final PythonImageBridge _bridge = PythonImageBridge();

  late String _originalSequence;
  String get originalSequence => _originalSequence;

  late String _currentSequence;
  String get currentSequence => _currentSequence;

  late Map<String, dynamic> _currentAnalysis;
  Map<String, dynamic> get currentAnalysis => _currentAnalysis;

  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  String? _error;
  String? get error => _error;

  void initialize(Map<String, dynamic> record) {
    _originalSequence = record['sequence'] ?? '';
    _currentSequence = _originalSequence;
    _currentAnalysis = record['analysis'] as Map<String, dynamic>? ?? {};
  }

  Future<void> updateSequence(int length, String db, {int limit = 100000}) async {
    _isAnalyzing = true;
    _error = null;
    _currentSequence = _originalSequence.substring(0, length);
    notifyListeners();

    try {
      final result = await _bridge.ncbiAnalyzeLocal(_currentSequence, db: db, limit: limit);
      _currentAnalysis = result['analysis'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      _error = e.toString();
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }
}
