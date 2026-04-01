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
      extendBodyBehindAppBar: true,
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Record Analysis'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              theme.colorScheme.surface.withValues(alpha: 0.8),
              theme.colorScheme.surfaceContainerLow,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.record['id'] ?? 'Unknown',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.record['description'] ?? 'No metadata description available for this record.',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Calibration controls layer
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 40,
                        spreadRadius: -4,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sequence Extent',
                            style: theme.textTheme.titleMedium,
                          ),
                          if (_isAnalyzing) 
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lengthController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: _onLengthChanged,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 18),
                        decoration: InputDecoration(
                          labelText: 'Base Pairs (1 - ${_originalSequence.length})',
                          fillColor: Colors.black, // surfaceContainerLowest
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'FAULT: $_error',
                          style: TextStyle(color: theme.colorScheme.error, letterSpacing: 1),
                        ),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 32), // spacing-8

                // Results Layer
                if (type == 'protein')
                  ProteinResultCard(result: ProteinAnalysisResult.fromJson(_currentAnalysis))
                else if (type == 'dna')
                  DnaResultCard(result: DnaClassificationResult.fromJson(_currentAnalysis)),
                
                const SizedBox(height: 32),

                // Sequence Extractor Display
                Text(
                  'Primary Sequence Data',
                  style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest, // deep black
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)),
                  ),
                  child: SelectableText(
                    _currentSequence,
                    style: TextStyle(
                      fontFamily: 'monospace', 
                      fontSize: 13,
                      height: 1.6,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
