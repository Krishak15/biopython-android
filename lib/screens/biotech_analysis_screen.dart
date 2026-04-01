import 'package:flutter/material.dart';

import '../services/biology_platform_bridge.dart';
import 'ncbi_search_results_screen.dart';

enum _AnalysisStatus { idle, ready, processing, error }

class BiotechAnalysisScreen extends StatefulWidget {
  const BiotechAnalysisScreen({super.key});

  @override
  State<BiotechAnalysisScreen> createState() => _BiotechAnalysisScreenState();
}

class _BiotechAnalysisScreenState extends State<BiotechAnalysisScreen> {
  final _bridge = PythonImageBridge();
  final _proteinController = TextEditingController();
  final _dnaController = TextEditingController();

  _AnalysisStatus _status = _AnalysisStatus.idle;
  String? _statusMessage;

  ProteinAnalysisResult? _proteinResult;
  String? _proteinError;

  DnaClassificationResult? _dnaResult;
  String? _dnaError;
  int _kmerSize = 3;

  final _ncbiController = TextEditingController();
  String _ncbiDb = 'protein';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _checkHealth();
  }

  @override
  void dispose() {
    _proteinController.dispose();
    _dnaController.dispose();
    _ncbiController.dispose();
    super.dispose();
  }

  Future<void> _checkHealth() async {
    debugPrint('[BiotechAnalysisScreen] _checkHealth: start');
    try {
      final health = await _bridge.healthBiology();
      final engineStatus = health['status'] as String? ?? 'IDLE';
      final error = health['error'] as String? ?? '';

      setState(() {
        _status = engineStatus == 'READY'
            ? _AnalysisStatus.ready
            : _AnalysisStatus.idle;
        _statusMessage = error.isEmpty ? 'Genomic Engine Initialized' : error;
      });
    } catch (e) {
      debugPrint('[BiotechAnalysisScreen] _checkHealth error: $e');
      setState(() {
        _status = _AnalysisStatus.error;
        _statusMessage = 'Engine Fault: $e';
      });
    }
  }

  Future<void> _analyzeProtein() async {
    final sequence = _proteinController.text.trim();
    if (sequence.isEmpty) {
      setState(() => _proteinError = 'Sequence required');
      return;
    }

    setState(() {
      _status = _AnalysisStatus.processing;
      _proteinResult = null;
      _proteinError = null;
      _statusMessage = 'Synthesizing protein structure...';
    });

    try {
      final result = await _bridge.analyzeProtein(sequence);
      setState(() {
        _proteinResult = result;
        _proteinError = null;
        _status = _AnalysisStatus.ready;
        _statusMessage = 'Protein diagnostics optimal.';
      });
    } on BiologyBridgeException catch (e) {
      setState(() {
        _proteinError = e.message;
        _status = _AnalysisStatus.error;
        _statusMessage = 'Failure: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _proteinError = 'Fault: $e';
        _status = _AnalysisStatus.error;
        _statusMessage = 'Diagnostics error: $e';
      });
    }
  }

  Future<void> _classifyDna() async {
    final sequence = _dnaController.text.trim();
    if (sequence.isEmpty) {
      setState(() => _dnaError = 'Sequence required');
      return;
    }

    setState(() {
      _status = _AnalysisStatus.processing;
      _dnaResult = null;
      _dnaError = null;
      _statusMessage = 'Sequence clustering engaged...';
    });

    try {
      final result = await _bridge.dnaClassify(sequence, kmerSize: _kmerSize);
      setState(() {
        _dnaResult = result;
        _dnaError = null;
        _status = _AnalysisStatus.ready;
        _statusMessage = 'Clustering complete. ${result.totalKmers} K-mers.';
      });
    } on BiologyBridgeException catch (e) {
      setState(() {
        _dnaError = e.message;
        _status = _AnalysisStatus.error;
        _statusMessage = 'Classification fail: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _dnaError = 'Fault: $e';
        _status = _AnalysisStatus.error;
        _statusMessage = 'Classification error: $e';
      });
    }
  }

  void _clearResults() {
    setState(() {
      _proteinController.clear();
      _dnaController.clear();
      _ncbiController.clear();
      _proteinResult = null;
      _proteinError = null;
      _dnaResult = null;
      _status = _AnalysisStatus.idle;
      _statusMessage = 'Awaiting input sequences.';
    });
  }

  Future<void> _searchNCBI() async {
    final query = _ncbiController.text.trim();
    if (query.isEmpty) {
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _bridge.ncbiSearch(query, db: _ncbiDb);
      if (!mounted) {
        return;
      }

      setState(() {
        _isSearching = false;
        if (results.isEmpty) {
          _statusMessage = 'Repository null response.';
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NcbiSearchResultsScreen(
                results: results,
                query: query,
                db: _ncbiDb,
              ),
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _statusMessage = 'Query connection failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Analysis Hub'),
        actions: [
          _StatusDot(status: _status),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _proteinResult != null || _dnaResult != null
                ? _clearResults
                : null,
            tooltip: 'Purge Memory',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          // "Editorial Luminescence" gradient
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              theme.colorScheme.surface.withValues(alpha: 0.9),
              theme.colorScheme.surfaceContainerLow,
            ],
            stops: const [0.0, 0.7],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              if (_statusMessage != null)
                Text(
                  _statusMessage!.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: _status == _AnalysisStatus.error
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
              const SizedBox(height: 32),

              // Protein Analysis Card
              _buildAnalysisCard(
                theme,
                title: 'Protein Analysis',
                description:
                    'Determine molecular weight, aromaticity, and GRAVY index from primary sequence data.',
                form: _SequenceInputField(
                  label: 'Peptide Input',
                  controller: _proteinController,
                  hint: 'Ex: MKTAYIAKQRQIS...',
                  error: _proteinError,
                ),
                action: _GradientButton(
                  label: 'Execute Diagnostics',
                  onPressed: _status != _AnalysisStatus.processing
                      ? _analyzeProtein
                      : null,
                  theme: theme,
                ),
                result: _proteinResult != null
                    ? ProteinResultCard(result: _proteinResult!)
                    : null,
              ),

              const SizedBox(height: 24), // spacing-6
              // DNA Classification Card
              _buildAnalysisCard(
                theme,
                title: 'Classification Analysis',
                description:
                    'Extract K-mer frequency topologies from genomic strings.',
                form: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SequenceInputField(
                      label: 'Nucleotide String',
                      controller: _dnaController,
                      hint: 'Ex: AGCTAGCTAGC...',
                      error: _dnaError,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('K-mer Scale:', style: theme.textTheme.labelLarge),
                        Expanded(
                          child: Slider(
                            value: _kmerSize.toDouble(),
                            min: 1,
                            max: 6,
                            divisions: 5,
                            activeColor: theme.colorScheme.secondary,
                            inactiveColor:
                                theme.colorScheme.surfaceContainerHighest,
                            label: '$_kmerSize bp',
                            onChanged: (v) =>
                                setState(() => _kmerSize = v.toInt()),
                          ),
                        ),
                        Text(
                          '$_kmerSize',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                action: _GradientButton(
                  label: 'Engage Clustering',
                  onPressed: _status != _AnalysisStatus.processing
                      ? _classifyDna
                      : null,
                  theme: theme,
                  isSecondary: true,
                ),
                result: _dnaResult != null
                    ? DnaResultCard(result: _dnaResult!)
                    : null,
              ),

              const SizedBox(height: 24),

              // NCBI Search Card
              _buildAnalysisCard(
                theme,
                title: 'Global Repository Search',
                description:
                    'Query NCBI databases directly for protein or nucleotide records.',
                form: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _SequenceInputField(
                        label: 'Query Term',
                        controller: _ncbiController,
                        hint: 'Ex: Human Insulin',
                        height: 60,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.15,
                            ),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _ncbiDb,
                            isExpanded: true,
                            dropdownColor:
                                theme.colorScheme.surfaceContainerHigh,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _ncbiDb = v);
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'protein',
                                child: Text('Protein'),
                              ),
                              DropdownMenuItem(
                                value: 'nucleotide',
                                child: Text('DNA/RNA'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                action: _GradientButton(
                  label: 'Transmit Query',
                  onPressed: _isSearching ? null : _searchNCBI,
                  theme: theme,
                  icon: _isSearching ? Icons.sync : Icons.radar,
                ),
              ),

              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisCard(
    ThemeData theme, {
    required String title,
    required String description,
    required Widget form,
    required Widget action,
    Widget? result,
  }) => Container(
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
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        form,
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: action),
        if (result != null) ...[const SizedBox(height: 24), result],
      ],
    ),
  );
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
    required this.theme,
    this.isSecondary = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final ThemeData theme;
  final bool isSecondary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = isSecondary
        ? [theme.colorScheme.secondary, theme.colorScheme.secondaryContainer]
        : [theme.colorScheme.primary, theme.colorScheme.primaryContainer];

    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: onPressed == null ? null : LinearGradient(colors: colors),
        color: onPressed == null
            ? theme.colorScheme.surfaceContainerHighest
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: onPressed == null
                        ? theme.colorScheme.onSurfaceVariant
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final _AnalysisStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      _AnalysisStatus.idle => theme.colorScheme.onSurfaceVariant,
      _AnalysisStatus.ready => Colors.greenAccent,
      _AnalysisStatus.processing => theme.colorScheme.primary,
      _AnalysisStatus.error => theme.colorScheme.error,
    };

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
        ],
      ),
    );
  }
}

class _SequenceInputField extends StatelessWidget {
  const _SequenceInputField({
    required this.label,
    required this.controller,
    required this.hint,
    this.error,
    this.height,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? error;
  final double? height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: TextField(
      controller: controller,
      maxLines: height == null ? 4 : 1,
      style: const TextStyle(fontFamily: 'monospace'),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        alignLabelWithHint: height == null,
      ),
    ),
  );
}

// Data Display Components matched to "The Ledger Style" (technical precision)

class ResultRow extends StatelessWidget {
  const ResultRow({required this.label, required this.value, super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProteinResultCard extends StatelessWidget {
  const ProteinResultCard({required this.result, super.key});
  final ProteinAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diagnostics Yield',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          ResultRow(label: 'MW', value: '${result.molecularWeight} Da'),
          ResultRow(
            label: 'Isoelectric Point',
            value: '${result.isoelectricPoint} pH',
          ),
          ResultRow(
            label: 'Aromaticity',
            value: result.aromaticity.toStringAsFixed(3),
          ),
          ResultRow(label: 'GRAVY', value: result.gravy.toStringAsFixed(3)),
          ResultRow(
            label: 'Instability',
            value: result.instabilityIndex.toStringAsFixed(2),
          ),
          ResultRow(
            label: 'Secondary Structure (Helix/Turn/Sheet)',
            value:
                '${(result.secondaryStructureFraction[0] * 100).toStringAsFixed(1)}% / ${(result.secondaryStructureFraction[1] * 100).toStringAsFixed(1)}% / ${(result.secondaryStructureFraction[2] * 100).toStringAsFixed(1)}%',
          ),
          ResultRow(
            label: 'Molar Extinction (Reduced/Oxidized)',
            value:
                '${result.molarExtinctionCoefficient[0]} / ${result.molarExtinctionCoefficient[1]} M⁻¹cm⁻¹',
          ),
          const SizedBox(height: 16),
          Text('Amino Acids', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.aminoAcidCounts.entries
                .where((e) => e.value > 0)
                .map(
                  (e) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${e.key}: ${e.value}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class DnaResultCard extends StatelessWidget {
  const DnaResultCard({required this.result, super.key});
  final DnaClassificationResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topKmers =
        (result.frequencies.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(8)
            .toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cluster Yield',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          ResultRow(label: 'Base Pairs', value: '${result.sequenceLength}'),
          ResultRow(
            label: 'GC Content',
            value: '${result.gcContent.toStringAsFixed(1)}%',
          ),
          ResultRow(
            label: 'Mol. Weight',
            value: '${result.molecularWeight.toStringAsFixed(2)} Da',
          ),
          if (result.meltingTemp > 0)
            ResultRow(
              label: 'Melting Temp',
              value: '${result.meltingTemp.toStringAsFixed(1)} °C',
            ),
          ResultRow(label: 'Total K-mers', value: '${result.totalKmers}'),
          ResultRow(
            label: 'Unique Nodes',
            value: '${result.frequencies.length}',
          ),
          const SizedBox(height: 16),
          Text('Primary Nodes', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: topKmers.length,
            itemBuilder: (context, i) {
              final kmer = topKmers[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      kmer.key,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${kmer.value}',
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          if (result.reverseComplement.isNotEmpty) ...[
            Text('Reverse Complement', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.15,
                  ),
                ),
              ),
              child: SelectableText(
                result.reverseComplement,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
