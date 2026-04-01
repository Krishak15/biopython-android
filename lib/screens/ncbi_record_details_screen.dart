import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/biology_platform_bridge.dart';
import 'biotech_analysis_screen.dart';
import 'dart:async';

class NcbiRecordDetailsScreen extends StatefulWidget {

  const NcbiRecordDetailsScreen({required this.record, super.key});
  final Map<String, dynamic> record;

  @override
  State<NcbiRecordDetailsScreen> createState() => _NcbiRecordDetailsScreenState();
}

class _NcbiRecordDetailsScreenState extends State<NcbiRecordDetailsScreen> {
  final _bridge = PythonImageBridge();
  late String _originalSequence;
  late String _currentSequence;
  late Map<String, dynamic> _currentAnalysis;
  
  final _lengthController = TextEditingController();
  Timer? _debounce;
  bool _isAnalyzing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _originalSequence = widget.record['sequence'] ?? '';
    _currentSequence = _originalSequence;
    _currentAnalysis = widget.record['analysis'] as Map<String, dynamic>? ?? {};
    _lengthController.text = _currentSequence.length.toString();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _lengthController.dispose();
    super.dispose();
  }

  void _onLengthChanged(String value) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final inputLength = int.tryParse(value);
      if (inputLength == null) {
        return;
      }

      var newLength = inputLength;
      if (newLength < 1) {
        newLength = 1;
      }
      if (newLength > _originalSequence.length) {
        newLength = _originalSequence.length;
      }

      if (_lengthController.text != newLength.toString()) {
        _lengthController.text = newLength.toString();
      }

      if (_currentSequence.length != newLength) {
        _updateSequence(newLength);
      }
    });
  }

  Future<void> _updateSequence(int length) async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
      _currentSequence = _originalSequence.substring(0, length);
    });

    try {
      final db = widget.record['analysis']['type'] == 'protein' ? 'protein' : 'nucleotide';
      final result = await _bridge.ncbiAnalyzeLocal(_currentSequence, db: db);
      setState(() {
        _currentAnalysis = result['analysis'] as Map<String, dynamic>? ?? {};
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = _currentAnalysis['type'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('NCBI Record Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.record['id'] ?? 'Unknown ID',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.record['description'] ?? 'No description',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adjust Sequence Length',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _lengthController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: _onLengthChanged,
                            decoration: InputDecoration(
                              labelText: 'Length (1 - ${_originalSequence.length})',
                              border: const OutlineInputBorder(),
                              suffixIcon: _isAnalyzing 
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: $_error',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (type == 'protein')
              ProteinResultCard(result: ProteinAnalysisResult.fromJson(_currentAnalysis))
            else if (type == 'dna')
              DnaResultCard(result: DnaClassificationResult.fromJson(_currentAnalysis)),
            const SizedBox(height: 24),

            const Text(
              'Sequence:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _currentSequence,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

