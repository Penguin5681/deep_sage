class AIModel {
  final String id;
  final String name;
  final String provider;
  final String description;
  final int parameterCount;
  final String size;
  final bool isLocal;
  final bool isInstalled;
  final double? downloadProgress;
  final String? localPath;
  final Map<String, dynamic> parameters;

  AIModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.description,
    required this.parameterCount,
    required this.size,
    required this.isLocal,
    required this.isInstalled,
    this.downloadProgress,
    this.localPath,
    required this.parameters,
  });
}
