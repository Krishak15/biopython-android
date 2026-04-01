import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/biology_platform_bridge.dart';
import '../providers/analysis_hub_provider.dart';
import '../theme/app_theme.dart';

class BiotechAnalysisScreen extends StatefulWidget {
  const BiotechAnalysisScreen({super.key});

  @override
  State<BiotechAnalysisScreen> createState() => _BiotechAnalysisScreenState();
}

class _BiotechAnalysisScreenState extends State<BiotechAnalysisScreen> {
  final _proteinController = TextEditingController();
  final _dnaController = TextEditingController();
  final _ncbiController = TextEditingController();
  final _scrollController = ScrollController();
  String _ncbiDb = 'protein';

  @override
  void initState() {
    super.initState();
    // Listen to provider to auto-scroll when analysis completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisHubProvider>().addListener(_onProviderChange);
    });
  }

  void _onProviderChange() {
    if (!mounted) {
      return;
    }
    final provider = context.read<AnalysisHubProvider>();
    if (provider.proteinResult != null || provider.dnaResult != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutQuart,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    context.read<AnalysisHubProvider>().removeListener(_onProviderChange);
    _proteinController.dispose();
    _dnaController.dispose();
    _ncbiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AnalysisHubProvider>();
    final status = provider.status;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.biotech,
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('BioPulse'),
          ],
        ),
        actions: [
          _StatusDot(status: status),
          const SizedBox(width: 8),
          IconButton(
            onPressed:
                provider.proteinResult != null || provider.dnaResult != null
                ? () {
                    _proteinController.clear();
                    _dnaController.clear();
                    _ncbiController.clear();
                    provider.clearResults();
                  }
                : null,
            tooltip: 'Purge Memory',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
            child: SafeArea(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                children: [
                  const _HeroSection(),
                  const SizedBox(height: 32),

                  _CalibrationPanel(
                    maxSequenceLength: provider.maxSequenceLength,
                    isSafetyLocked: provider.isSafetyLocked,
                    onChanged: provider.setMaxSequenceLength,
                    onLockChanged: (v) =>
                        provider.toggleSafetyLock(isLocked: v),
                  ),
                  const SizedBox(height: 32),

                  _bentoCard(
                    theme: theme,
                    accentColor: AppTheme.primary,
                    icon: Icons.hexagon_outlined,
                    title: 'Proteomics Workbench',
                    subtitle: 'FASTA Source / Raw Chain',
                    child: Column(
                      children: [
                        _SequenceInputField(
                          label: 'PEPTIDE INPUT',
                          controller: _proteinController,
                          hint: 'Ex: MFVFLVLLPLVSSQCVNLTTR...',
                          error: provider.proteinError,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _GradientButton(
                                label: 'EXECUTE ANALYSIS',
                                onPressed: status != AnalysisStatus.processing
                                    ? () => provider.analyzeProtein(
                                        _proteinController.text.trim(),
                                      )
                                    : null,
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SecondaryButton(
                                label: 'RESET',
                                onPressed: _proteinController.clear,
                                theme: theme,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _bentoCard(
                    theme: theme,
                    accentColor: AppTheme.secondary,
                    icon: Icons.grain_outlined,
                    title: 'K-mer Logic',
                    subtitle: 'K-Length Parameter',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'SCALE',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  Text(
                                    'k=${provider.kmerSize}',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: AppTheme.secondary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: provider.kmerSize.toDouble(),
                                min: 1,
                                max: 12,
                                divisions: 11,
                                activeColor: AppTheme.secondary,
                                inactiveColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                onChanged: (v) =>
                                    provider.setKmerSize(v.toInt()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SequenceInputField(
                          label: 'NUCLEOTIDE STRING',
                          controller: _dnaController,
                          hint: 'Ex: AGCTAGCTAGC...',
                          error: provider.dnaError,
                        ),
                        const SizedBox(height: 24),
                        _GradientButton(
                          label: 'PROCESS FRAGMENTS',
                          onPressed: status != AnalysisStatus.processing
                              ? () => provider.classifyDna(
                                  _dnaController.text.trim(),
                                )
                              : null,
                          theme: theme,
                          isSecondary: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _bentoCard(
                    theme: theme,
                    accentColor: AppTheme.tertiary,
                    icon: Icons.storage_outlined,
                    title: 'Entrez Query Engine',
                    subtitle: 'Database Selection',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _ncbiDb,
                                    isExpanded: true,
                                    dropdownColor:
                                        theme.colorScheme.surfaceContainerHigh,
                                    icon: const Icon(
                                      Icons.expand_more,
                                      size: 20,
                                    ),
                                    onChanged: (v) => v != null
                                        ? setState(() => _ncbiDb = v)
                                        : null,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'protein',
                                        child: Text('Protein Archive'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'nucleotide',
                                        child: Text('Nucleotide Database'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _ncbiController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 20),
                            hintText: 'Accession number, DOI, or term...',
                            suffixIcon: IconButton(
                              onPressed: provider.isSearching
                                  ? null
                                  : () => provider.searchNCBI(
                                      context,
                                      _ncbiController.text.trim(),
                                      _ncbiDb,
                                    ),
                              icon: provider.isSearching
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.cloud_download_outlined),
                              color: AppTheme.tertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 64),

                  if (provider.proteinResult != null) ...[
                    _ResultHero(
                      theme: theme,
                      title: 'Analysis Results',
                      child: ProteinResultCard(result: provider.proteinResult!),
                    ),
                    const SizedBox(height: 48),
                  ],

                  if (provider.dnaResult != null) ...[
                    _ResultHero(
                      theme: theme,
                      title: 'Cluster Yield',
                      child: DnaResultCard(result: provider.dnaResult!),
                    ),
                    const SizedBox(height: 48),
                  ],
                ],
              ),
            ),
          ),
          if (provider.status == AnalysisStatus.processing)
            _TelemetryOverlay(telemetry: provider.telemetry),
        ],
      ),
    );
  }

  Widget _bentoCard({
    required ThemeData theme,
    required Color accentColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLow.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
      ),
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
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                Text(subtitle.toUpperCase(), style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        child,
      ],
    ),
  );
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workspace Alpha-9'.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Genomic Intelligence Center.',
          style: theme.textTheme.displayMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'Integrated analytical suite for high-throughput protein modeling, DNA k-mer classification, and multi-omics data retrieval.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _TruncationWarning extends StatelessWidget {
  const _TruncationWarning({
    required this.originalLength,
    required this.limitUsed,
  });

  final int originalLength;
  final int limitUsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Analytical Snapshot: Sequence truncated from ${originalLength.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} to ${limitUsed.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} for mobile stability.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalibrationPanel extends StatefulWidget {
  const _CalibrationPanel({
    required this.maxSequenceLength,
    required this.isSafetyLocked,
    required this.onChanged,
    required this.onLockChanged,
  });

  final int maxSequenceLength;
  final bool isSafetyLocked;
  final ValueChanged<int> onChanged;
  final ValueChanged<bool> onLockChanged;

  @override
  State<_CalibrationPanel> createState() => _CalibrationPanelState();
}

class _CalibrationPanelState extends State<_CalibrationPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isSafetyLocked
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            leading: Icon(
              widget.isSafetyLocked
                  ? Icons.security_rounded
                  : Icons.lock_open_rounded,
              color: widget.isSafetyLocked
                  ? theme.colorScheme.primary
                  : Colors.orange,
              size: 20,
            ),
            title: Text(
              'Hardware Calibration',
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            trailing: Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 20,
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SAFETY LOCK',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                        ),
                      ),
                      Switch.adaptive(
                        value: widget.isSafetyLocked,
                        onChanged: widget.onLockChanged,
                        activeTrackColor: theme.colorScheme.primary.withValues(
                          alpha: 0.5,
                        ),
                        activeThumbColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MAX SEQUENCE LENGTH',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                        ),
                      ),
                      Text(
                        '${(widget.maxSequenceLength / 1000).toInt()}K Bases',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: widget.isSafetyLocked
                              ? theme.colorScheme.primary
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: widget.isSafetyLocked
                          ? null
                          : Colors.orange,
                      thumbColor: widget.isSafetyLocked ? null : Colors.orange,
                    ),
                    child: Slider(
                      value: widget.maxSequenceLength.toDouble(),
                      min: 10000,
                      max: widget.isSafetyLocked ? 100000 : 5000000,
                      divisions: widget.isSafetyLocked ? 9 : 499,
                      onChanged: (v) => widget.onChanged(v.toInt()),
                    ),
                  ),
                  if (!widget.isSafetyLocked) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_rounded,
                            color: Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'HIGH PERFORMANCE MODE ACTIVE: SYSTEM STABILITY MAY BE REDUCED ON LARGER DATASETS.',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.orange,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Higher values increase analytical depth but may cause instability on low-end devices.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TelemetryOverlay extends StatelessWidget {
  const _TelemetryOverlay({required this.telemetry});

  final Map<String, dynamic>? telemetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usedMem = telemetry?['usedMemory'] ?? 0;
    final maxMem = telemetry?['maxMemory'] ?? 1;
    final memPercent = (usedMem / maxMem).clamp(0.0, 1.0);

    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'PROCESSING',
                    style: theme.textTheme.labelLarge?.copyWith(
                      letterSpacing: 4,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _TelemetryRow(
                    label: 'JVM HEAP',
                    value: '${usedMem}MB',
                    percent: memPercent,
                    color: memPercent > 0.8 ? Colors.amber : AppTheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const _TelemetryRow(
                    label: 'CORE LOAD',
                    value: 'ACTIVE',
                    percent: 0.9,
                    color: AppTheme.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultHero extends StatelessWidget {
  const _ResultHero({
    required this.theme,
    required this.title,
    required this.child,
  });
  final ThemeData theme;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      child,
    ],
  );
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
    required this.theme,
    this.isSecondary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ThemeData theme;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final activeColors = isSecondary
        ? const [AppTheme.secondary, AppTheme.secondaryContainer]
        : const [AppTheme.primary, AppTheme.primaryContainer];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: disabled
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: activeColors,
              ),
        color: disabled ? theme.colorScheme.surfaceContainerHighest : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: disabled
                    ? theme.colorScheme.onSurfaceVariant
                    : Colors.black87,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    required this.theme,
  });

  final String label;
  final VoidCallback? onPressed;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Container(
    height: 56,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: theme.colorScheme.surfaceContainerHighest,
      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    ),
  );
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});
  final AnalysisStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (status) {
      AnalysisStatus.idle => theme.colorScheme.onSurfaceVariant,
      AnalysisStatus.ready => Colors.greenAccent,
      AnalysisStatus.processing => theme.colorScheme.primary,
      AnalysisStatus.error => theme.colorScheme.error,
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
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: AppTheme.primary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: error,
            fillColor: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class ResultRow extends StatelessWidget {
  const ResultRow({required this.label, required this.value, super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
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

    return Column(
      children: [
        if (result.isTruncated)
          _TruncationWarning(
            originalLength: result.originalLength,
            limitUsed: result.limitUsed,
          ),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DETAILED PROFILE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                  const Icon(
                    Icons.analytics_outlined,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2,
                children: [
                  ResultRow(
                    label: 'MW',
                    value: '${result.molecularWeight.toStringAsFixed(2)} Da',
                  ),
                  ResultRow(
                    label: 'pI',
                    value: result.isoelectricPoint.toStringAsFixed(2),
                  ),
                  ResultRow(
                    label: 'AROMATICITY',
                    value: result.aromaticity.toStringAsFixed(3),
                  ),
                  ResultRow(
                    label: 'INSTABILITY',
                    value: result.instabilityIndex.toStringAsFixed(2),
                  ),
                  ResultRow(
                    label: 'GRAVY',
                    value: result.gravy.toStringAsFixed(3),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _TechnicalSection(
                theme: theme,
                label: 'SECONDARY STRUCTURE FRACTION',
                value:
                    'Helix: ${(result.secondaryStructureFraction[0] * 100).toStringAsFixed(1)}% | Turn: ${(result.secondaryStructureFraction[1] * 100).toStringAsFixed(1)}% | Sheet: ${(result.secondaryStructureFraction[2] * 100).toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 12),
              _TechnicalSection(
                theme: theme,
                label: 'MOLAR EXTINCTION COEFFICIENT',
                value:
                    'Reduced: ${result.molarExtinctionCoefficient[0]} | Oxidized: ${result.molarExtinctionCoefficient[1]} M⁻¹cm⁻¹',
              ),
              const SizedBox(height: 24),
              Text('AMINO ACID COMPOSITION', style: theme.textTheme.labelSmall),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.aminoAcidCounts.entries
                    .where((e) => e.value > 0)
                    .map((e) => _MetricBadge(label: e.key, value: '${e.value}'))
                    .toList(),
              ),
            ],
          ),
        ),
      ],
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
            .take(6)
            .toList();

    return Column(
      children: [
        const SizedBox(height: 16),
        if (result.isTruncated)
          _TruncationWarning(
            originalLength: result.originalLength,
            limitUsed: result.limitUsed,
          ),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GENOMIC DIAGNOSTICS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.secondary,
                    ),
                  ),
                  const Icon(
                    Icons.query_stats_outlined,
                    color: AppTheme.secondary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2,
                children: [
                  ResultRow(
                    label: 'BASE PAIRS',
                    value: '${result.sequenceLength}',
                  ),
                  ResultRow(
                    label: 'GC CONTENT',
                    value: '${result.gcContent.toStringAsFixed(1)}%',
                  ),
                  ResultRow(
                    label: 'MOL. WEIGHT',
                    value:
                        '${(result.molecularWeight / 1000).toStringAsFixed(2)} kDa',
                  ),
                  ResultRow(
                    label: 'MELTING TEMP',
                    value: '${result.meltingTemp.toStringAsFixed(1)} °C',
                  ),
                  ResultRow(
                    label: 'TOTAL K-MERS',
                    value: '${result.totalKmers}',
                  ),
                  ResultRow(
                    label: 'UNIQUE NODES',
                    value: '${result.frequencies.length}',
                  ),
                ],
              ),
              if (result.reverseComplement.isNotEmpty) ...[
                const SizedBox(height: 16),
                _TechnicalSection(
                  theme: theme,
                  label: 'REVERSE COMPLEMENT',
                  value: result.reverseComplement,
                  isMonospace: true,
                  onCopy: () {
                    Clipboard.setData(
                      ClipboardData(text: result.reverseComplement),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reverse complement copied'),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
              Text('PRIMARY K-MER NODES', style: theme.textTheme.labelSmall),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: topKmers
                    .map(
                      (e) => _MetricBadge(
                        label: e.key,
                        value: '${e.value}',
                        color: AppTheme.secondary,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TechnicalSection extends StatelessWidget {
  const _TechnicalSection({
    required this.theme,
    required this.label,
    required this.value,
    this.isMonospace = false,
    this.onCopy,
  });

  final ThemeData theme;
  final String label;
  final String value;
  final bool isMonospace;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.05),
      ),
    ),
    child: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 8,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.only(right: onCopy != null ? 32 : 0),
              child: Text(
                value,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontFamily: isMonospace ? 'monospace' : null,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        if (onCopy != null)
          Positioned(
            right: -8,
            top: -8,
            child: IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 14),
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
      ],
    ),
  );
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.label,
    required this.value,
    this.color = AppTheme.primary,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.1)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _TelemetryRow extends StatelessWidget {
  const _TelemetryRow({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  final String label;
  final String value;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 8),
            ),
            Text(
              value,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percent,
          minHeight: 2,
          backgroundColor: color.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ],
    );
  }
}
