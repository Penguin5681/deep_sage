class OllamaModelInfo {
  final String modelId;
  final String modelName;
  final String variant;
  final String notes;
  final String runCommand;

  OllamaModelInfo({
    required this.modelId,
    required this.modelName,
    required this.variant,
    required this.notes,
    required this.runCommand,
  });

  factory OllamaModelInfo.fromJson(Map<String, dynamic> json) {
    return OllamaModelInfo(
      modelId: json['Model ID'] ?? '',
      modelName: json['Model Name'] ?? '',
      variant: json['Variant'] ?? '',
      notes: json['Notes'] ?? '',
      runCommand: json['Run Command'] ?? '',
    );
  }
}
