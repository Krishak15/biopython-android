import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('com.akdev.app/python_bridge');

/// Exception thrown when Python bridge operations fail.
class BiologyBridgeException implements Exception {
  const BiologyBridgeException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'BiologyBridgeException[$code]: $message';
}

/// Result from protein sequence analysis.
class ProteinAnalysisResult {
  const ProteinAnalysisResult({
    required this.molecularWeight,
    required this.isoelectricPoint,
    required this.aromaticity,
    required this.instabilityIndex,
    required this.gravy,
    required this.secondaryStructureFraction,
    required this.molarExtinctionCoefficient,
    required this.aminoAcidCounts,
  });

  factory ProteinAnalysisResult.fromJson(Map<String, dynamic> json) {
    final counts = json['amino_acid_counts'];
    final aminoAcidCounts = <String, int>{};
    if (counts is Map) {
      counts.forEach((key, value) {
        aminoAcidCounts[key.toString()] = (value as num).toInt();
      });
    }

    final secStruct = json['secondary_structure_fraction'] as List<dynamic>? ?? [0.0, 0.0, 0.0];
    final molarExt = json['molar_extinction_coefficient'] as List<dynamic>? ?? [0, 0];

    return ProteinAnalysisResult(
      molecularWeight: (json['molecular_weight'] as num?)?.toDouble() ?? 0.0,
      isoelectricPoint: (json['isoelectric_point'] as num?)?.toDouble() ?? 0.0,
      aromaticity: (json['aromaticity'] as num?)?.toDouble() ?? 0.0,
      instabilityIndex: (json['instability_index'] as num?)?.toDouble() ?? 0.0,
      gravy: (json['gravy'] as num?)?.toDouble() ?? 0.0,
      secondaryStructureFraction: secStruct.map((e) => (e as num).toDouble()).toList(),
      molarExtinctionCoefficient: molarExt.map((e) => (e as num).toInt()).toList(),
      aminoAcidCounts: aminoAcidCounts,
    );
  }

  /// Molecular weight in Daltons.
  final double molecularWeight;

  /// Isoelectric point (pH at which protein has no net charge).
  final double isoelectricPoint;

  /// Relative frequency of Phe+Trp+Tyr.
  final double aromaticity;

  /// Instability index (values > 40 indicate unstable proteins).
  final double instabilityIndex;

  /// Grand Average of Hydropathy (GRAVY) indicating hydrophobicity.
  final double gravy;

  /// Fraction of [Helix, Turn, Sheet] based on typical scales.
  final List<double> secondaryStructureFraction;

  /// Molar extinction coefficient [reduced, oxidized].
  final List<int> molarExtinctionCoefficient;

  /// Map of amino acid symbols to their counts in the sequence.
  final Map<String, int> aminoAcidCounts;
}

/// Result from DNA k-mer classification/analysis.
class DnaClassificationResult {
  const DnaClassificationResult({
    required this.kmerSize,
    required this.sequenceLength,
    required this.totalKmers,
    required this.frequencies,
  });

  factory DnaClassificationResult.fromJson(Map<String, dynamic> json) {
    final freqs = json['frequencies'];
    final frequencies = <String, int>{};
    if (freqs is Map) {
      freqs.forEach((key, value) {
        frequencies[key.toString()] = (value as num).toInt();
      });
    }

    return DnaClassificationResult(
      kmerSize: (json['kmer_size'] as num?)?.toInt() ?? 3,
      sequenceLength: (json['sequence_length'] as num?)?.toInt() ?? 0,
      totalKmers: (json['total_kmers'] as num?)?.toInt() ?? 0,
      frequencies: frequencies,
    );
  }

  /// Size of k-mers used (e.g., 3 for 3-mers).
  final int kmerSize;

  /// Length of input DNA sequence.
  final int sequenceLength;

  /// Total number of k-mers found in sequence.
  final int totalKmers;

  /// Map of k-mer strings to their frequency counts.
  final Map<String, int> frequencies;
}

/// Bridge to Python biology analysis modules (protein and DNA sequence analysis).
class PythonImageBridge {
  /// Check health and availability of biology analysis modules.
  ///
  /// Returns a map containing:
  /// - status: "READY" or "ERROR"
  /// - model: "biology-analysis-v1"
  /// - error: error message (empty if no errors)
  Future<Map<String, dynamic>> healthBiology() async {
    debugPrint('[PythonImageBridge] healthBiology: start');
    try {
      final raw = await _channel.invokeMethod<dynamic>('healthBiology');
      Map<String, dynamic> jsonMap;
      if (raw == null) {
        jsonMap = {};
      } else if (raw is String) {
        jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      } else if (raw is Map) {
        jsonMap = raw.map((key, value) => MapEntry(key.toString(), value));
      } else {
        jsonMap = {};
      }
      debugPrint('[PythonImageBridge] healthBiology: $jsonMap');
      return jsonMap;
    } on PlatformException catch (e) {
      debugPrint(
        '[PythonImageBridge] healthBiology error: code=${e.code} message=${e.message}',
      );
      throw BiologyBridgeException(
        e.message ?? 'Biology module health check failed',
        code: e.code,
      );
    }
  }

  /// Analyze a protein sequence to extract biochemical properties.
  ///
  /// Args:
  ///   sequence: Amino acid sequence string (e.g., "MKTAYIAK")
  ///
  /// Returns: ProteinAnalysisResult with molecular weight, isoelectric point,
  ///   and amino acid counts.
  ///
  /// Throws: BiologyBridgeException on analysis failure.
  Future<ProteinAnalysisResult> analyzeProtein(String sequence) async {
    debugPrint(
      '[PythonImageBridge] analyzeProtein: sequenceLength=${sequence.length}',
    );
    try {
      final raw = await _channel.invokeMethod<String>('proteinAnalyze', {
        'sequence': sequence,
      });
      final jsonMap = jsonDecode(raw ?? '{}') as Map<String, dynamic>;
      final status = jsonMap['status'] as String?;

      if (status != 'success') {
        throw BiologyBridgeException(
          jsonMap['message'] as String? ?? 'Protein analysis failed',
          code: 'ANALYSIS_ERROR',
        );
      }

      final result = ProteinAnalysisResult.fromJson(jsonMap);
      debugPrint(
        '[PythonImageBridge] analyzeProtein: success MW=${result.molecularWeight}',
      );
      return result;
    } on PlatformException catch (e) {
      debugPrint(
        '[PythonImageBridge] analyzeProtein error: code=${e.code} message=${e.message}',
      );
      throw BiologyBridgeException(
        e.message ?? 'Protein analysis failed',
        code: e.code,
      );
    }
  }

  /// Perform DNA sequence classification via k-mer frequency analysis.
  ///
  /// Args:
  ///   sequence: DNA sequence string (should contain only ATCG characters)
  ///   kmerSize: Size of k-mers to extract (default 3, range 1-6 typical)
  ///
  /// Returns: DnaClassificationResult with k-mer frequencies.
  ///
  /// Throws: BiologyBridgeException on classification failure.
  Future<DnaClassificationResult> dnaClassify(
    String sequence, {
    int kmerSize = 3,
  }) async {
    debugPrint(
      '[PythonImageBridge] dnaClassify: sequenceLength=${sequence.length} kmerSize=$kmerSize',
    );
    try {
      final raw = await _channel.invokeMethod<String>('dnaClassify', {
        'sequence': sequence,
        'kmerSize': kmerSize,
      });
      final jsonMap = jsonDecode(raw ?? '{}') as Map<String, dynamic>;
      final status = jsonMap['status'] as String?;

      if (status != 'success') {
        throw BiologyBridgeException(
          jsonMap['message'] as String? ?? 'DNA classification failed',
          code: 'CLASSIFICATION_ERROR',
        );
      }

      final result = DnaClassificationResult.fromJson(jsonMap);
      debugPrint(
        '[PythonImageBridge] dnaClassify: success kmers=${result.totalKmers}',
      );
      return result;
    } on PlatformException catch (e) {
      debugPrint(
        '[PythonImageBridge] dnaClassify error: code=${e.code} message=${e.message}',
      );
      throw BiologyBridgeException(
        e.message ?? 'DNA classification failed',
        code: e.code,
      );
    }
  }

  /// Legacy method for backward compatibility. Use analyzeProtein() instead.
  @Deprecated('Use analyzeProtein() instead')
  Future<Map<String, dynamic>> healthCheck() => healthBiology();
}
