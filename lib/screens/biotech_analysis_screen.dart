import 'package:flutter/material.dart';

import '../services/biology_bridge_exception.dart';

enum _AnalysisStatus { idle, ready, processing, error }

/// DNA Classification & Protein Analysis Demo Screen
///
/// Demonstrates offline BioPython capabilities for molecular biology research.
/// - Protein Analysis: molecular weight, isoelectric point, amino acid composition
/// - DNA Classification: k-mer frequency analysis for sequence identification
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

  // Protein analysis results
  ProteinAnalysisResult? _proteinResult;
  String? _proteinError;

  // DNA analysis results
  DnaClassificationResult? _dnaResult;
  String? _dnaError;
  int _kmerSize = 3;

  // NCBI search results
  final _ncbiController = TextEditingController();
  List<Map<String, dynamic>> _ncbiResults = [];
  Map<String, dynamic>? _selectedRecord;
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
        _statusMessage = error.isEmpty
            ? 'BioPython analysis engine ready. Enter sequences to analyze.'
            : error;
      });
    } catch (e) {
      debugPrint('[BiotechAnalysisScreen] _checkHealth error: $e');
      setState(() {
        _status = _AnalysisStatus.error;
        _statusMessage = 'Failed to initialize biology engine: $e';
      });
    }
  }

  Future<void> _analyzeProtein() async {
    final sequence = _proteinController.text.trim();
    if (sequence.isEmpty) {
      setState(() {
        _proteinError = 'Please enter a protein sequence';
      });
      return;
    }

    setState(() {
      _status = _AnalysisStatus.processing;
      _proteinResult = null;
      _proteinError = null;
      _statusMessage = 'Analyzing protein sequence...';
    });

    try {
      final result = await _bridge.analyzeProtein(sequence);
      setState(() {
        _proteinResult = result;
        _proteinError = null;
        _status = _AnalysisStatus.ready;
        _statusMessage =
            'Protein analysis complete. MW: ${result.molecularWeight} Da';
      });
    } on BiologyBridgeException catch (e) {
      setState(() {
        _proteinError = e.message;
        _status = _AnalysisStatus.error;
        _statusMessage = 'Protein analysis failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _proteinError = 'Unexpected error: $e';
        _status = _AnalysisStatus.error;
        _statusMessage = 'Protein analysis error: $e';
      });
    }
  }

  Future<void> _classifyDna() async {
    final sequence = _dnaController.text.trim();
    if (sequence.isEmpty) {
      setState(() {
        _dnaError = 'Please enter a DNA sequence';
      });
      return;
    }

    setState(() {
      _status = _AnalysisStatus.processing;
      _dnaResult = null;
      _dnaError = null;
      _statusMessage = 'Classifying DNA sequence...';
    });

    try {
      final result = await _bridge.dnaClassify(sequence, kmerSize: _kmerSize);
      setState(() {
        _dnaResult = result;
        _dnaError = null;
        _status = _AnalysisStatus.ready;
        _statusMessage =
            'DNA classification complete. ${result.totalKmers} k-mers found.';
      });
    } on BiologyBridgeException catch (e) {
      setState(() {
        _dnaError = e.message;
        _status = _AnalysisStatus.error;
        _statusMessage = 'DNA classification failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _dnaError = 'Unexpected error: $e';
        _status = _AnalysisStatus.error;
        _statusMessage = 'DNA classification error: $e';
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
      _dnaError = null;
      _ncbiResults = [];
      _selectedRecord = null;
      _status = _AnalysisStatus.idle;
      _statusMessage = 'Ready for new sequences.';
    });
  }

  Future<void> _searchNCBI() async {
    final query = _ncbiController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _ncbiResults = [];
      _selectedRecord = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Searching NCBI...')),
    );

    try {
      final results = await _bridge.ncbiSearch(query, db: _ncbiDb);
      setState(() {
        _ncbiResults = results;
        _isSearching = false;
        if (results.isEmpty) {
          _statusMessage = 'No results found.';
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No results found.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Found ${results.length} results.')),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _statusMessage = 'Search failing: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e'), backgroundColor: Colors.red),
        );
      });
    }
  }

  Future<void> _fetchAndAnalyze(String id) async {
    setState(() {
      _isSearching = true;
      _selectedRecord = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fetching record $id...')),
    );

    try {
      final record = await _bridge.ncbiFetch(id, db: _ncbiDb);
      setState(() {
        _selectedRecord = record;
        _isSearching = false;
        _statusMessage = 'Fetched and analyzed record: $id';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis complete!')),
        );
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _statusMessage = 'Fetch failing: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fetch failed: $e'), backgroundColor: Colors.red),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BioPython Sequence Analysis'),
        actions: [
          _StatusChip(status: _status),
          IconButton(
            onPressed: _proteinResult != null || _dnaResult != null
                ? _clearResults
                : null,
            tooltip: 'Clear results',
            icon: const Icon(Icons.clear_all_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_statusMessage != null)
                    _Banner(
                      message: _statusMessage!,
                      isError: _status == _AnalysisStatus.error,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Offline molecular biology analysis with BioPython.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Analyze protein sequences and DNA k-mers without internet access.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  // Protein Analysis Section
                  const _SectionHeader(title: 'Protein Sequence Analysis'),
                  const SizedBox(height: 12),
                  _SequenceInputField(
                    label: 'Protein Sequence',
                    controller: _proteinController,
                    hint:
                        'e.g., MKTAYIAKQRQISFVKSHFSRQLEERLGLIEVQAPILSRVGDGTQDNLSGAEK',
                    error: _proteinError,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _status != _AnalysisStatus.processing
                        ? _analyzeProtein
                        : null,
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Analyze Protein'),
                  ),
                  if (_proteinResult != null) ...[
                    const SizedBox(height: 16),
                    _ProteinResultCard(result: _proteinResult!),
                  ],
                  const SizedBox(height: 32),
                  // DNA Classification Section
                  const _SectionHeader(title: 'DNA K-mer Classification'),
                  const SizedBox(height: 12),
                  _SequenceInputField(
                    label: 'DNA Sequence',
                    controller: _dnaController,
                    hint: 'e.g., AGCTAGCTAGCTAGCTAGCT',
                    error: _dnaError,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'K-mer size: $_kmerSize',
                              style: theme.textTheme.labelMedium,
                            ),
                            Slider(
                              value: _kmerSize.toDouble(),
                              min: 1,
                              max: 6,
                              divisions: 5,
                              label: '$_kmerSize',
                              onChanged: (value) {
                                setState(() {
                                  _kmerSize = value.toInt();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _status != _AnalysisStatus.processing
                        ? _classifyDna
                        : null,
                    icon: const Icon(Icons.hub_outlined),
                    label: const Text('Classify DNA'),
                  ),
                  if (_dnaResult != null) ...[
                    const SizedBox(height: 16),
                    _DnaResultCard(result: _dnaResult!),
                  ],
                  const SizedBox(height: 32),
                  // NCBI Search Section
                  const _SectionHeader(title: 'NCBI Database Search'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SequenceInputField(
                          label: 'Search NCBI',
                          controller: _ncbiController,
                          hint: 'Search for proteins/genes (e.g., insulin)',
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _ncbiDb,
                        onChanged: (String? newValue) {
                          if (newValue != null) setState(() => _ncbiDb = newValue);
                        },
                        items: const [
                          DropdownMenuItem(value: 'protein', child: Text('Protein')),
                          DropdownMenuItem(value: 'nucleotide', child: Text('DNA/RNA')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isSearching ? null : _searchNCBI,
                    icon: _isSearching 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.search),
                    label: const Text('Search NCBI'),
                  ),
                  if (_ncbiResults.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _ncbiResults.length,
                      itemBuilder: (context, index) {
                        final res = _ncbiResults[index];
                        return ListTile(
                          title: Text(res['title'], maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('ID: ${res['id']}'),
                          trailing: const Icon(Icons.analytics_outlined),
                          onTap: () => _fetchAndAnalyze(res['id']),
                        );
                      },
                    ),
                  ],
                  if (_selectedRecord != null) ...[
                    const SizedBox(height: 16),
                    _NcbiRecordCard(record: _selectedRecord!),
                  ],
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _AnalysisStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _AnalysisStatus.idle => ('Idle', Colors.blueGrey),
      _AnalysisStatus.ready => ('Ready', Colors.green.shade700),
      _AnalysisStatus.processing => ('Processing', Colors.indigo.shade700),
      _AnalysisStatus.error => ('Error', Colors.red.shade700),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Chip(
        label: Text(label, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isError ? Colors.red.shade50 : Colors.green.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isError ? Colors.red.shade200 : Colors.green.shade200,
      ),
    ),
    child: Text(
      message,
      style: TextStyle(
        color: isError ? Colors.red.shade900 : Colors.green.shade900,
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _SequenceInputField extends StatelessWidget {
  const _SequenceInputField({
    required this.label,
    required this.controller,
    required this.hint,
    this.error,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? error;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLines: 4,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.8),
    ),
    style: const TextStyle(fontFamily: 'monospace'),
  );
}

class _ProteinResultCard extends StatelessWidget {
  const _ProteinResultCard({required this.result});

  final ProteinAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Protein Analysis Results',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _ResultRow(
              label: 'Molecular Weight',
              value: '${result.molecularWeight} Da',
            ),
            const SizedBox(height: 8),
            _ResultRow(
              label: 'Isoelectric Point',
              value: '${result.isoelectricPoint} pH',
            ),
            const SizedBox(height: 8),
            _ResultRow(
              label: 'Aromaticity',
              value: result.aromaticity.toStringAsFixed(3),
            ),
            const SizedBox(height: 8),
            _ResultRow(
              label: 'Instability Index',
              value: result.instabilityIndex.toStringAsFixed(2),
            ),
            const SizedBox(height: 8),
            _ResultRow(
              label: 'GRAVY',
              value: result.gravy.toStringAsFixed(3),
            ),
            const SizedBox(height: 8),
            _ResultRow(
              label: 'Secondary Structure (Helix/Turn/Sheet)',
              value: '${(result.secondaryStructureFraction[0] * 100).toStringAsFixed(1)}% / ${(result.secondaryStructureFraction[1] * 100).toStringAsFixed(1)}% / ${(result.secondaryStructureFraction[2] * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 8),
            _ResultRow(
              label: 'Molar Extinction (Reduced/Oxidized)',
              value: '${result.molarExtinctionCoefficient[0]} / ${result.molarExtinctionCoefficient[1]} M⁻¹cm⁻¹',
            ),
            const SizedBox(height: 16),
            Text('Amino Acid Composition', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: result.aminoAcidCounts.entries
                  .map(
                    (entry) => Chip(
                      label: Text('${entry.key}: ${entry.value}'),
                      side: BorderSide(color: theme.colorScheme.primary),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DnaResultCard extends StatelessWidget {
  const _DnaResultCard({required this.result});

  final DnaClassificationResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topKmers = (result.frequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)))
      .take(10)
      .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DNA K-mer Classification Results',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _ResultRow(
              label: 'Sequence Length',
              value: '${result.sequenceLength} bp',
            ),
            const SizedBox(height: 8),
            _ResultRow(label: 'K-mer Size', value: '${result.kmerSize}-mers'),
            const SizedBox(height: 8),
            _ResultRow(
              label: 'Total K-mers Found',
              value: result.totalKmers.toString(),
            ),
            const SizedBox(height: 8),
            _ResultRow(
              label: 'Unique K-mers',
              value: result.frequencies.length.toString(),
            ),
            const SizedBox(height: 16),
            Text('Top 10 Frequent K-mers', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('K-mer')),
                  DataColumn(label: Text('Count')),
                ],
                rows: topKmers
                    .map(
                      (entry) => DataRow(
                        cells: [
                          DataCell(
                            Text(
                              entry.key,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                          DataCell(Text(entry.value.toString())),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NcbiRecordCard extends StatelessWidget {
  const _NcbiRecordCard({required this.record});
  final Map<String, dynamic> record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysis = record['analysis'] as Map<String, dynamic>;
    final type = analysis['type'];

    return Card(
      elevation: 4,
      color: theme.colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NCBI Record Analysis',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(record['description'], style: theme.textTheme.bodySmall),
            const Divider(),
            if (type == 'protein') ...[
              _ResultRow(label: 'MW', value: '${analysis['molecular_weight']} Da'),
              _ResultRow(label: 'pI', value: '${analysis['isoelectric_point']}'),
              _ResultRow(label: 'GRAVY', value: '${analysis['gravy']}'),
            ] else ...[
              _ResultRow(label: 'GC Content', value: '${analysis['gc_content']}%'),
              _ResultRow(label: 'Length', value: '${analysis['length']} bp'),
            ],
            const SizedBox(height: 12),
            const Text('Sequence (First 100 bp/aa):', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              record['sequence'].toString().substring(0, record['sequence'].toString().length > 100 ? 100 : record['sequence'].toString().length) + '...',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
