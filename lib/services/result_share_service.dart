import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../services/biology_platform_bridge.dart';

class ResultShareService {
  static Future<void> shareProteinResult(
    ScreenshotController controller,
    ProteinAnalysisResult result, {
    String? ncbiId,
    String? itemName,
  }) async {
    final image = await controller.capture();
    if (image == null) {
      return;
    }

    final directory = await getTemporaryDirectory();
    final imagePath = await File(
      '${directory.path}/protein_analysis.png',
    ).create();
    await imagePath.writeAsBytes(image);

    final text =
        '''
🔬 BIOPULSE PROTEOMICS REPORT
${itemName != null ? 'Target: $itemName\n' : ''}Molecular Weight: ${result.molecularWeight.toStringAsFixed(2)} Da
Isoelectric Point: ${result.isoelectricPoint.toStringAsFixed(2)}
Aromaticity: ${result.aromaticity.toStringAsFixed(3)}
Instability Index: ${result.instabilityIndex.toStringAsFixed(2)}
GRAVY: ${result.gravy.toStringAsFixed(3)}
Structure: Helix: ${(result.secondaryStructureFraction[0] * 100).toStringAsFixed(1)}% | Turn: ${(result.secondaryStructureFraction[1] * 100).toStringAsFixed(1)}% | Sheet: ${(result.secondaryStructureFraction[2] * 100).toStringAsFixed(1)}%
${ncbiId != null ? '\nSOURCE: https://www.ncbi.nlm.nih.gov/protein/$ncbiId' : ''}
''';

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(imagePath.path)],
        text: text,
        subject: 'BioPulse Proteomics Analysis',
      ),
    );
  }

  static Future<void> shareDnaResult(
    ScreenshotController controller,
    DnaClassificationResult result, {
    String? ncbiId,
    String? itemName,
  }) async {
    final image = await controller.capture();
    if (image == null) {
      return;
    }

    final directory = await getTemporaryDirectory();
    final imagePath = await File('${directory.path}/dna_analysis.png').create();
    await imagePath.writeAsBytes(image);

    final text =
        '''
BIOPULSE GENOMIC REPORT
${itemName != null ? 'Target: $itemName\n' : ''}Base Pairs: ${result.sequenceLength}
GC Content: ${result.gcContent.toStringAsFixed(1)}%
Molecular Weight: ${(result.molecularWeight / 1000).toStringAsFixed(2)} kDa
Melting Temp: ${result.meltingTemp.toStringAsFixed(1)} °C
Total K-mers: ${result.totalKmers}
Unique Nodes: ${result.frequencies.length}
${ncbiId != null ? '\nSOURCE: https://www.ncbi.nlm.nih.gov/nuccore/$ncbiId' : ''}
''';

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(imagePath.path)],
        text: text,
        subject: 'BioPulse Genomic Analysis',
      ),
    );
  }
}
