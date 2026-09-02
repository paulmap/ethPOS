import 'dart:io';

/// Which model this phone can actually hold in RAM.
enum ModelTier { none, tiny, small, medium, large }

class ModelSpec {
  final ModelTier tier;
  final String name;
  final String fileName;

  /// Download size, shown on the first-launch screen.
  final int downloadMb;
  final int minRamMb;

  const ModelSpec({
    required this.tier,
    required this.name,
    required this.fileName,
    required this.downloadMb,
    required this.minRamMb,
  });

  static const none = ModelSpec(
    tier: ModelTier.none,
    name: 'Rules only',
    fileName: '',
    downloadMb: 0,
    minRamMb: 0,
  );

  /// int4-quantised GGUF/TFLite builds. Sizes are approximate on-disk.
  static const catalogue = <ModelSpec>[
    ModelSpec(
      tier: ModelTier.large,
      name: 'Qwen2.5 7B',
      fileName: 'qwen2.5-7b-instruct-q4_k_m.gguf',
      downloadMb: 4400,
      minRamMb: 8192,
    ),
    ModelSpec(
      tier: ModelTier.medium,
      name: 'Llama 3.2 3B',
      fileName: 'llama-3.2-3b-instruct-q4_k_m.gguf',
      downloadMb: 2000,
      minRamMb: 6144,
    ),
    ModelSpec(
      tier: ModelTier.small,
      name: 'Gemma 2 2B',
      fileName: 'gemma-2-2b-it-q4_k_m.gguf',
      downloadMb: 1500,
      minRamMb: 3584,
    ),
    ModelSpec(
      tier: ModelTier.tiny,
      name: 'Qwen2.5 0.5B',
      fileName: 'qwen2.5-0.5b-instruct-q4_k_m.gguf',
      downloadMb: 400,
      minRamMb: 2048,
    ),
  ];
}

/// Reads real device RAM and picks a model. No user-facing choice: the tier is
/// decided here and only surfaced as a line on the first-launch screen.
class DeviceTier {
  static int? _cachedRamMb;

  /// Total physical RAM in MB, or null if it cannot be determined.
  static Future<int?> totalRamMb() async {
    if (_cachedRamMb != null) return _cachedRamMb;
    try {
      if (Platform.isAndroid || Platform.isLinux) {
        final meminfo = File('/proc/meminfo');
        if (await meminfo.exists()) {
          final line = (await meminfo.readAsLines()).firstWhere(
            (l) => l.startsWith('MemTotal'),
            orElse: () => '',
          );
          final kb = int.tryParse(
            RegExp(r'(\d+)').firstMatch(line)?.group(1) ?? '',
          );
          if (kb != null) return _cachedRamMb = (kb / 1024).round();
        }
      }
    } catch (_) {
      // Fall through to the conservative default below.
    }
    // iOS/desktop: wire a platform channel to ProcessInfo.processInfo
    // .physicalMemory if you need exact figures. Until then assume a modest
    // device so we never pick a model that will be killed by the OS.
    return _cachedRamMb = null;
  }

  /// Leaves headroom for Flutter, Hive and the camera: a model may claim at
  /// most ~45% of RAM.
  static Future<ModelSpec> recommended() async {
    final ram = await totalRamMb() ?? 3072;
    for (final spec in ModelSpec.catalogue) {
      if (ram >= spec.minRamMb) return spec;
    }
    return ModelSpec.none;
  }

  static String describe(int? ramMb) =>
      ramMb == null ? 'Unknown device' : '${(ramMb / 1024).round()} GB RAM';
}
