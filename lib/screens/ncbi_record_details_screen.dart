import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../services/biology_platform_bridge.dart';
import '../providers/ncbi_record_provider.dart';
import 'biotech_analysis_screen.dart';

class NcbiRecordDetailsScreen extends StatelessWidget {
  const NcbiRecordDetailsScreen({required this.record, super.key});
  final Map<String, dynamic> record;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
      create: (_) => NcbiRecordProvider()..initialize(record),
      child: _NcbiRecordDetailsContent(record: record),
    );
}

class _NcbiRecordDetailsContent extends StatefulWidget {
  const _NcbiRecordDetailsContent({required this.record});
  final Map<String, dynamic> record;

  @override
  State<_NcbiRecordDetailsContent> createState() => _NcbiRecordDetailsContentState();
}

class _NcbiRecordDetailsContentState extends State<_NcbiRecordDetailsContent> {
  final _lengthController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Initialize length controller text with max sequence length 
    // Wait until build completes to grab provider sequence 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final prov = context.read<NcbiRecordProvider>();
        _lengthController.text = prov.currentSequence.length.toString();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _lengthController.dispose();
    super.dispose();
  }

  void _onLengthChanged(String value, NcbiRecordProvider provider) {
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
      if (newLength > provider.originalSequence.length) {
        newLength = provider.originalSequence.length;
      }

      if (_lengthController.text != newLength.toString()) {
        _lengthController.text = newLength.toString();
      }

      if (provider.currentSequence.length != newLength) {
        final db = widget.record['analysis']['type'] == 'protein' ? 'protein' : 'nucleotide';
        provider.updateSequence(newLength, db);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<NcbiRecordProvider>();
    final type = provider.currentAnalysis['type'] ?? widget.record['analysis']?['type'];

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
                      ),
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
                          if (provider.isAnalyzing) 
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lengthController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (v) => _onLengthChanged(v, context.read<NcbiRecordProvider>()),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 18),
                        decoration: InputDecoration(
                          labelText: 'Base Pairs (1 - ${provider.originalSequence.isNotEmpty ? provider.originalSequence.length : widget.record['sequence']?.length ?? 0})',
                          fillColor: Colors.black, // surfaceContainerLowest
                        ),
                      ),
                      if (provider.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'FAULT: ${provider.error}',
                          style: TextStyle(color: theme.colorScheme.error, letterSpacing: 1),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32), // spacing-8

                // Results Layer
                if (type == 'protein' && provider.currentAnalysis.isNotEmpty)
                  ProteinResultCard(result: ProteinAnalysisResult.fromJson(provider.currentAnalysis))
                else if (type == 'nucleotide' && provider.currentAnalysis.isNotEmpty)
                  DnaResultCard(result: DnaClassificationResult.fromJson(provider.currentAnalysis)),
                
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
                    color: Colors.black, // surfaceContainerLowest
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)),
                  ),
                  child: SelectableText(
                    provider.currentSequence,
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
