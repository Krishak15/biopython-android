import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../services/biology_platform_bridge.dart';
import '../providers/ncbi_record_provider.dart';
import '../theme/app_theme.dart';
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
      appBar: AppBar(
        title: const Text('Accession Analysis'),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Repository Metadata Hero
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.tertiary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'NCBI ACCESSION: ${widget.record['id'] ?? 'Unknown'}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppTheme.tertiary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (provider.isAnalyzing)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.record['description'] ?? 'Repository data stream active.',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                
                // Calibration controls layer
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SEQUENCE CALIBRATION',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _lengthController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (v) => _onLengthChanged(v, context.read<NcbiRecordProvider>()),
                        style: const TextStyle(
                          fontFamily: 'monospace', 
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.tertiary,
                        ),
                        decoration: InputDecoration(
                          labelText: 'SUB-FRAG LENGTH (MAX ${provider.originalSequence.length})',
                          fillColor: Colors.black.withValues(alpha: 0.3),
                        ),
                      ),
                      if (provider.error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'SYSTEM FAULT: ${provider.error}',
                          style: TextStyle(
                            color: theme.colorScheme.error, 
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Results Layer
                if (type == 'protein' && provider.currentAnalysis.isNotEmpty)
                  ProteinResultCard(result: ProteinAnalysisResult.fromJson(provider.currentAnalysis))
                else if (type == 'nucleotide' && provider.currentAnalysis.isNotEmpty)
                  DnaResultCard(result: DnaClassificationResult.fromJson(provider.currentAnalysis)),
                
                const SizedBox(height: 48),

                // Sequence Extractor Display
                Row(
                  children: [
                    Text(
                      'PRIMARY DATA STREAM',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: provider.currentSequence));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sequence copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    provider.currentSequence,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      height: 1.8,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
