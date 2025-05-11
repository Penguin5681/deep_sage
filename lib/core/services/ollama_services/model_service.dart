import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:deep_sage/core/models/ai_model.dart';

import '../../models/ollama_data_models/ollama_model_info.dart';

class ModelService {
  final String baseUrl = dotenv.env['DEV_BASE_URL']!;

  /// Fetches available models from Ollama
  Future<List<OllamaModelInfo>> getAvailableOllamaModels() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/ollama/get-available-models'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'success' && data['models'] != null) {
          List<OllamaModelInfo> models =
              (data['models'] as List)
                  .map((modelJson) => OllamaModelInfo.fromJson(modelJson))
                  .toList();

          models.sort((a, b) => a.modelName.compareTo(b.modelName));
          return models;
        } else {
          throw Exception('Failed to parse models data');
        }
      } else {
        throw Exception('Failed to load models: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching models: $e');
    }
  }

  AIModel convertToAIModel(
    OllamaModelInfo ollamaModel, {
    List<String> installedModelIds = const [],
  }) {
    String id = ollamaModel.modelId;

    // Check if this model is installed
    bool isInstalled = installedModelIds.contains(id);

    int parameterCount = 7;
    final variantStr = ollamaModel.variant;
    RegExp regExp = RegExp(r'(\d+)b');
    final match = regExp.firstMatch(variantStr);
    if (match != null && match.group(1) != null) {
      parameterCount = int.parse(match.group(1)!);
    }

    double sizeMultiplier = 0.6;
    if (parameterCount >= 20) {
      sizeMultiplier = 0.65;
    } else if (parameterCount <= 2) {
      sizeMultiplier = 0.5;
    }

    String size = '${(parameterCount * sizeMultiplier).toStringAsFixed(1)} GB';

    return AIModel(
      id: id,
      name: '${ollamaModel.modelName} ${ollamaModel.variant}',
      provider: 'Ollama',
      description: ollamaModel.notes,
      parameterCount: parameterCount,
      size: size,
      isLocal: isInstalled,
      isInstalled: isInstalled,
      parameters: {'temperature': 0.7, 'top_p': 0.9, 'max_tokens': 2048},
    );
  }

  Future<List<AIModel>> getAvailableModelsAsAIModels() async {
    final ollamaModels = await getAvailableOllamaModels();
    final installedModelIds = await getInstalledModelIds();

    List<AIModel> aiModels =
        ollamaModels
            .map(
              (model) =>
                  convertToAIModel(model, installedModelIds: installedModelIds),
            )
            .toList();

    aiModels.sort((a, b) {
      if (a.isInstalled && !b.isInstalled) return -1;
      if (!a.isInstalled && b.isInstalled) return 1;
      return a.name.compareTo(b.name);
    });

    return aiModels;
  }

  Future<List<String>> getInstalledModelIds({String? modelId}) async {
    try {
      final Map<String, dynamic> requestBody = {};
      if (modelId != null) {
        requestBody['model_id'] = modelId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/ollama/models/installed'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success' && data['installed_models'] != null) {
          return List<String>.from(data['installed_models']);
        } else {
          debugPrint('Invalid response format: ${response.body}');
          return [];
        }
      } else {
        debugPrint(
          'Failed to fetch installed models: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching installed models: $e');
      return [];
    }
  }

  /// Remove a downloaded model
  Future<void> removeModel(String modelId) async {
    try {
      await http.delete(
        Uri.parse('$baseUrl/api/ollama/models/$modelId'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      throw Exception('Error removing model: $e');
    }
  }

  // lib/core/services/ollama_services/model_service.dart

  Future<void> downloadModel(String modelId) async {
    final uri = Uri.parse('$baseUrl/api/ollama/models/download');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'model_id': modelId}),
    );

    if (response.statusCode != 202) {
      throw Exception(
        'Failed to start download: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> data = json.decode(response.body);
    if (data['status'] != 'success') {
      throw Exception('Download error: ${data['message'] ?? response.body}');
    }
  }

  Future<double?> getModelDownloadStatus(String modelId) async {
    final uri = Uri.parse('$baseUrl/api/ollama/models/status/$modelId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final prog = data['progress'];
      if (prog is num) {
        return prog.toDouble();
      }
    }
    return null;
  }

  Future<void> cancelDownload(String modelId) async {
    final url = Uri.parse('$baseUrl/api/ollama/models/cancel/$modelId');
    final response = await http.delete(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to cancel download: ${response.body}');
    }
  }
}
