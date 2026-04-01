import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../providers/analysis_hub_provider.dart';
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
  State<_NcbiRecordDetailsContent> createState() =>
      _NcbiRecordDetailsContentState();
}

class _NcbiRecordDetailsContentState extends State<_NcbiRecordDetailsContent> {
  final _lengthController = TextEditingController();
  Timer? _debounce;

  late AnalysisHubProvider _hub;

  @override
  void initState() {
    super.initState();
    _hub = context.read<AnalysisHubProvider>();
    _hub.startManualTelemetry();
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
    _hub.stopManualTelemetry();
    super.dispose();
  }

  void _onLengthChanged(
    String value,
    NcbiRecordProvider provider, {
    required bool isLocked,
  }) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final inputLength = int.tryParse(value);
      if (inputLength == null) {
        return;
      }

      var newLength = inputLength;

      // Enforce Safety Lock (100K max)
      if (isLocked && newLength > 100000) {
        newLength = 100000;
      }

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
        final db = widget.record['analysis']['type'] == 'protein'
            ? 'protein'
            : 'nucleotide';
        provider.updateSequence(newLength, db, limit: newLength);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<NcbiRecordProvider>();
    final type =
        provider.currentAnalysis['type'] ?? widget.record['analysis']?['type'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Accession Analysis')),
      body: Container(
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
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
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.record['description'] ??
                          'Repository data stream active.',
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
                Consumer<AnalysisHubProvider>(
                  builder: (context, hub, _) {
                    final isLocked = hub.isSafetyLocked;
                    final accentColor = isLocked
                        ? AppTheme.tertiary
                        : Colors.orange;

                    return Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow.withValues(
                          alpha: 0.7,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SEQUENCE CALIBRATION',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: accentColor,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    isLocked
                                        ? Icons.security_rounded
                                        : Icons.lock_open_rounded,
                                    size: 14,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Switch.adaptive(
                                    value: isLocked,
                                    onChanged: (v) =>
                                        hub.toggleSafetyLock(isLocked: v),
                                    activeTrackColor: AppTheme.primary
                                        .withValues(alpha: 0.5),
                                    activeThumbColor: AppTheme.primary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _lengthController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (v) => _onLengthChanged(
                              v,
                              context.read<NcbiRecordProvider>(),
                              isLocked: isLocked,
                            ),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                            decoration: InputDecoration(
                              labelText: isLocked
                                  ? 'SUB-FRAG LENGTH (HP LOCKED: MAX 100K)'
                                  : 'SUB-FRAG LENGTH (HP ACTIVE)',
                              fillColor: Colors.black.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                              activeTrackColor: accentColor,
                              thumbColor: accentColor,
                            ),
                            child: Slider(
                              value: hub.maxSequenceLength.toDouble().clamp(
                                10000,
                                5000000,
                              ),
                              min: 10000,
                              max: isLocked ? 100000 : 5000000,
                              divisions: isLocked ? 9 : 499,
                              onChanged: (v) {
                                hub.setMaxSequenceLength(v.toInt());
                                // Automatically update the analysis for the current accession
                                final currentLimit = v.toInt();
                                final clampedLimit = currentLimit.clamp(
                                  1,
                                  provider.originalSequence.length,
                                );
                                _lengthController.text = clampedLimit
                                    .toString();
                                _onLengthChanged(
                                  clampedLimit.toString(),
                                  context.read<NcbiRecordProvider>(),
                                  isLocked: isLocked,
                                );
                              },
                            ),
                          ),
                          if (!isLocked) ...[
                            const SizedBox(height: 16),
                            const _PerformanceGuardrail(),
                          ],
                          if (!isLocked) ...[
                            const SizedBox(height: 12),
                            Text(
                              'HIGH PERFORMANCE MODE ACTIVE. PROCEED WITH CAUTION.',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.orange,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                          if (provider.error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              'SYSTEM FAULT: ${provider.error}',
                              style: TextStyle(
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.8,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                // Results Layer
                Column(
                  children: [
                    const SizedBox(height: 16),
                    if (provider.isAnalyzing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            color:
                                provider.currentAnalysis['limit_used'] !=
                                        null &&
                                    (provider.currentAnalysis['limit_used']
                                                as num)
                                            .toInt() >
                                        100000
                                ? Colors.orange
                                : AppTheme.primary,
                            backgroundColor: AppTheme.primary.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                      ),
                    if (type == 'protein' &&
                        provider.currentAnalysis.isNotEmpty)
                      ProteinResultCard(
                        result: ProteinAnalysisResult.fromJson(
                          provider.currentAnalysis,
                        ),
                      )
                    else if (type == 'nucleotide' &&
                        provider.currentAnalysis.isNotEmpty)
                      DnaResultCard(
                        result: DnaClassificationResult.fromJson(
                          provider.currentAnalysis,
                        ),
                      ),

                    if (provider.currentAnalysis.isNotEmpty &&
                        !provider.isAnalyzing) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 12,
                            color: Colors.greenAccent.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'VALIDATED SNAPSHOT: ${provider.currentAnalysis['limit_used'] ?? 'Default'} BASES',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 8,
                              color: Colors.white24,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 48),

                // Sequence Extractor Display
                Row(
                  children: [
                    Text(
                      'PRIMARY DATA STREAM',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: provider.currentSequence),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sequence copied to clipboard'),
                          ),
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
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                  child: Text(
                    provider.currentSequence,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      height: 1.8,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
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

class _PerformanceGuardrail extends StatelessWidget {
  const _PerformanceGuardrail();

  @override
  Widget build(BuildContext context) {
    final hub = context.watch<AnalysisHubProvider>();
    final factor = hub.deviceStressFactor;
    final level = hub.deviceRiskLevel;

    Color statusColor;
    String warning;

    switch (level) {
      case 'OPTIMAL':
        statusColor = Colors.greenAccent;
        warning = 'System stability optimal. Low analytical risk.';
        break;
      case 'STRESSED':
        statusColor = Colors.orangeAccent;
        warning = 'High memory load detected. Manual calibration advised.';
        break;
      case 'CRITICAL':
        statusColor = AppTheme.error;
        warning = 'Critical resource depletion. System failure risk is high.';
        break;
      default:
        statusColor = Colors.white24;
        warning = 'Monitoring system resources...';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SYSTEM HEALTH: $level',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 8,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${(factor * 100).toInt()}% LOAD',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: statusColor.withValues(alpha: 0.5),
                  fontSize: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: factor,
            backgroundColor: statusColor.withValues(alpha: 0.1),
            color: statusColor,
            minHeight: 1,
          ),
          const SizedBox(height: 12),
          Text(
            warning,
            style: TextStyle(
              color: statusColor.withValues(alpha: 0.7),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
