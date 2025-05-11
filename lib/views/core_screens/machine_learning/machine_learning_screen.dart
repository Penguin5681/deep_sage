import 'package:deep_sage/core/services/ollama_services/model_service.dart';
import 'package:deep_sage/core/services/ollama_services/ollama_chat_services.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:math';
import 'package:deep_sage/core/models/chat_message.dart';
import 'package:flutter/services.dart';

import '../../../core/models/ai_model.dart';
import '../../../core/models/chat_session.dart';
import '../../../core/models/hive_models/chat_message_hive.dart';
import '../../../core/models/hive_models/chat_session_hive.dart';

class MachineLearningScreen extends StatefulWidget {
  const MachineLearningScreen({super.key});

  @override
  State<MachineLearningScreen> createState() => _MachineLearningScreenState();
}

class _MachineLearningScreenState extends State<MachineLearningScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final OllamaChatService _chatService;
  late final String _userId;

  late String? currentDatasetPath = '';
  late String? currentDatasetType = '';
  late String? currentDatasetName = '';
  bool _isDatasetSelected = false;
  bool _isSidebarExpanded = false;
  bool _isTyping = false;
  AIModel? _selectedModel;
  String _modelFilter = 'all';
  bool _showModelSettings = false;

  final ModelService _modelService = ModelService();
  bool _isLoadingModels = false;
  String? _loadingError;
  List<AIModel> _availableModels = [];
  final Map<String, double> _downloadProgress = {};

  final TextEditingController _modelSearchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  late TabController _tabController;
  final Map<String, Timer> _pollingTimers = {};

  final Box recentImportsBox = Hive.box(dotenv.env['RECENT_IMPORTS_HISTORY']!);
  late final FocusNode _messageFocusNode;

  final List<ChatSession> _sessions = [];
  ChatSession? _selectedSession;
  bool _showChatSessions = false;

  void _createSession() async {
    final hive = await _chatService.createSession(
      _userId,
      title: 'New Chat',
      model: _selectedModel?.id ?? 'mistral',
    );
    final newSession = ChatSession(id: hive.sessionId, nickname: hive.title);
    setState(() {
      _sessions.insert(0, newSession);
      _selectedSession = newSession;
    });
  }

  void _selectSession(ChatSession session) {
    setState(() {
      _selectedSession = session;
    });
    _loadMessages(session);
  }

  void _deleteSession(ChatSession session) {
    setState(() {
      _sessions.remove(session);
      if (_selectedSession == session) {
        _selectedSession = _sessions.isNotEmpty ? _sessions.first : null;
      }
    });
  }

  void _renameSession(ChatSession session) {
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: session.nickname);
        return AlertDialog(
          title: Text('Rename Chat'),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  try {
                    await _chatService.updateSessionTitle(
                      session.id,
                      _userId,
                      newTitle,
                    );
                    setState(() => session.nickname = newTitle);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to rename chat: ${e.toString()}'),
                      ),
                    );
                  }
                }
                if (!context.mounted) return;
                Navigator.pop(ctx);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchOllamaModels() async {
    setState(() {
      _isLoadingModels = true;
      _loadingError = null;
    });

    try {
      final models = await _modelService.getAvailableModelsAsAIModels();

      // Check which models are installed
      final installedModelIds = await _modelService.getInstalledModelIds();

      setState(() {
        _availableModels =
            models.map((model) {
              return AIModel(
                id: model.id,
                name: model.name,
                provider: model.provider,
                description: model.description,
                parameterCount: model.parameterCount,
                size: model.size,
                isLocal: model.isLocal,
                isInstalled: installedModelIds.contains(model.id),
                parameters: model.parameters,
              );
            }).toList();

        // Select first installed model or first available model
        if (_availableModels.isNotEmpty) {
          _selectedModel = _availableModels.firstWhere(
            (model) => model.isInstalled,
            orElse: () => _availableModels.first,
          );
        } else {
          _selectedModel = null;
        }

        _isLoadingModels = false;
      });
    } catch (e) {
      setState(() {
        _loadingError = e.toString();
        _isLoadingModels = false;
      });
    }
  }

  // Download model from Ollama
  Future<void> _downloadModel(AIModel model) async {
    try {
      setState(() {
        _downloadProgress[model.id] = 0.0;
      });

      await _modelService.downloadModel(model.id);

      // Start polling for download status
      _startDownloadStatusPolling(model.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Started downloading ${model.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading model: ${e.toString()}')),
      );
    }
  }

  void _startDownloadStatusPolling(String modelId) {
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      try {
        final progress = await _modelService.getModelDownloadStatus(modelId);

        setState(() {
          if (progress != null) {
            _downloadProgress[modelId] = progress;
          }

          if (progress == 1.0) {
            timer.cancel();
            _pollingTimers.remove(modelId);
            setState(() {
              _downloadProgress.remove(modelId);
            });
            _updateModelInstallStatus(modelId, true);
          }
        });
      } catch (e) {}
    });
    _pollingTimers.remove(modelId);
  }

  Future<void> _cancelDownload(AIModel model) async {
    try {
      await _modelService.cancelDownload(model.id);
      _pollingTimers[model.id]?.cancel();
      setState(() => _downloadProgress.remove(model.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancelled download of ${model.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
    }
  }

  // Update model installation status
  void _updateModelInstallStatus(String modelId, bool isInstalled) {
    setState(() {
      _availableModels =
          _availableModels.map((model) {
            if (model.id == modelId) {
              return AIModel(
                id: model.id,
                name: model.name,
                provider: model.provider,
                description: model.description,
                parameterCount: model.parameterCount,
                size: model.size,
                isLocal: model.isLocal,
                isInstalled: isInstalled,
                parameters: model.parameters,
              );
            }
            return model;
          }).toList();
    });
  }

  void loadDatasetMetadata() {
    currentDatasetPath = recentImportsBox.get('currentDatasetPath');
    currentDatasetType = recentImportsBox.get('currentDatasetType');
    currentDatasetName = recentImportsBox.get('currentDatasetName');

    _isDatasetSelected =
        currentDatasetPath != null &&
        currentDatasetPath!.isNotEmpty &&
        currentDatasetName != null &&
        currentDatasetName!.isNotEmpty;
  }

  // Update the _sendMessage method in machine_learning_screen.dart
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _selectedSession == null) return;

    final session = _selectedSession!;
    setState(() {
      // Add the user's message
      session.messages.add(
        ChatMessage(text: text, isUserMessage: true, timestamp: DateTime.now()),
      );
      _messageController.clear();
      _isTyping = true;

      // Add a single placeholder message for the AI response
      session.messages.add(
        ChatMessage(
          text: "",
          isUserMessage: false,
          timestamp: DateTime.now(),
          isTyping: true,
        ),
      );
    });
    _scrollToBottom();

    try {
      // Get the stream of response chunks
      final responseStream = await _chatService.sendMessageStream(
        session.id,
        _userId,
        text,
      );
      String responseBuffer = "";

      // Listen to the stream chunks
      await for (final chunk in responseStream) {
        setState(() {
          // Update the buffer with new content
          responseBuffer += chunk;

          // Replace the last message (typing indicator) with the updated content
          final lastIndex = session.messages.length - 1;
          session.messages[lastIndex] = ChatMessage(
            text: responseBuffer,
            isUserMessage: false,
            timestamp: DateTime.now(),
            isTyping: false, // Not typing anymore, showing actual text
          );
        });
        _scrollToBottom();
      }

      // Stream is complete
      setState(() {
        _isTyping = false;
      });
    } catch (e) {
      // Handle errors
      setState(() {
        _isTyping = false;
        // Replace typing indicator with error message
        final lastIndex = session.messages.length - 1;
        session.messages[lastIndex] = ChatMessage(
          text: "Error: ${e.toString()}",
          isUserMessage: false,
          timestamp: DateTime.now(),
          isError: true,
        );
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _selectModel(AIModel model) {
    setState(() {
      _selectedModel = model;
      _showModelSettings = false;
    });

    // Add a system message about model change
    _messages.add(
      ChatMessage(
        text: "Switched to model: ${model.name}",
        isUserMessage: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _toggleModelSettings() {
    setState(() {
      _showModelSettings = !_showModelSettings;
    });
  }

  // Method to simulate loading a GGUF model
  void _showLoadModelDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Load GGUF Model'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select a GGUF model file from your computer:'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Browse Files'),
                  onPressed: () {
                    // This would be connected to file picker in Phase 3
                    Navigator.of(context).pop();

                    // Simulate adding a new model
                    final newModel = AIModel(
                      id: 'custom-model-${DateTime.now().millisecondsSinceEpoch}',
                      name: 'Custom Model',
                      provider: 'Local GGUF',
                      description: 'User uploaded model',
                      parameterCount: 7,
                      size: '3.8 GB',
                      isLocal: true,
                      isInstalled: true,
                      localPath: '/path/to/custom/model.gguf',
                      parameters: {
                        'temperature': 0.7,
                        'top_p': 0.9,
                        'max_tokens': 2048,
                      },
                    );

                    // Add new model to list and select it
                    setState(() {
                      _availableModels.add(newModel);
                      _selectedModel = newModel;
                    });

                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Custom model loaded successfully'),
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _removeModel(AIModel model) async {
    try {
      await _modelService.removeModel(model.id);
      setState(() {
        _availableModels.removeWhere((m) => m.id == model.id);
        if (_selectedModel?.id == model.id) {
          _selectedModel =
              _availableModels.isNotEmpty ? _availableModels.first : null;
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed ${model.name} successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove ${model.name}: $e')),
      );
    }
  }

  List<AIModel> _getFilteredModels() {
    String searchText = _modelSearchController.text.toLowerCase();
    return _availableModels.where((model) {
      bool matchesFilter =
          _modelFilter == 'all' ||
          (_modelFilter == 'ollama' && model.provider == 'Ollama') ||
          (_modelFilter == 'local' && model.isLocal);
      bool matchesSearch =
          searchText.isEmpty ||
          model.name.toLowerCase().contains(searchText) ||
          model.description.toLowerCase().contains(searchText);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _messageFocusNode = FocusNode();
    _initHiveBoxes().then((_) {
      _chatService = OllamaChatService();
      _tabController = TabController(length: 3, vsync: this);

      fetchOllamaModels();
      _userId = Hive.box(dotenv.env['USER_HIVE_BOX']!).get('userId');
      _loadSessions();

      _messages.add(
        ChatMessage(
          text:
              "Welcome to the AI Chat! Select a model from the sidebar to begin.",
          isUserMessage: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  Future<void> _initHiveBoxes() async {
    if (!Hive.isBoxOpen('chat_sessions')) {
      await Hive.openBox<ChatSessionHive>('chat_sessions');
    }
    if (!Hive.isBoxOpen('chat_messages')) {
      await Hive.openBox<ChatMessageHive>('chat_messages');
    }
  }

  Future<void> _loadSessions() async {
    final hiveSessions = await _chatService.listSessions(_userId);
    setState(() {
      _sessions.clear();
      _sessions.addAll(
        hiveSessions.map(
          (s) => ChatSession(id: s.sessionId, nickname: s.title),
        ),
      );
      if (_sessions.isNotEmpty) {
        _selectedSession = _sessions.first;
        _loadMessages(_selectedSession!);
      }
    });
  }

  Future<void> _loadMessages(ChatSession session) async {
    final hiveMsgs = await _chatService.getChatMessages(session.id, _userId);
    setState(() {
      session.messages
        ..clear()
        ..addAll(
          hiveMsgs.map(
            (m) => ChatMessage(
              text: m.content,
              isUserMessage: m.role == 'user',
              timestamp: m.createdAt,
            ),
          ),
        );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _modelSearchController.dispose();
    _tabController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Widget _buildModelList() {
    if (_isLoadingModels) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading available models...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_loadingError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading models',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _loadingError!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchOllamaModels,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredModels = _getFilteredModels();

    if (filteredModels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No models found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_modelSearchController.text.isNotEmpty || _modelFilter != 'all')
              const SizedBox(height: 8),
            if (_modelSearchController.text.isNotEmpty || _modelFilter != 'all')
              Text(
                'Try adjusting your filters',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredModels.length,
      itemBuilder: (context, index) {
        final model = filteredModels[index];
        final isSelected = _selectedModel?.id == model.id;
        final isDownloading = _downloadProgress.containsKey(model.id);
        final downloadProgress = _downloadProgress[model.id];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).cardColor,
          elevation: isSelected ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                isSelected
                    ? BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1,
                    )
                    : BorderSide.none,
          ),
          child: InkWell(
            onTap: () => _selectModel(model),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          model.isLocal ? Icons.folder : Icons.cloud,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              model.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${model.parameterCount}B parameters • ${model.size}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (model.isInstalled)
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.red,
                              ),
                              tooltip: 'Remove model',
                              onPressed: () => _removeModel(model),
                            ),
                          ],
                        )
                      else if (isDownloading)
                        Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                value: downloadProgress,
                                strokeWidth: 2,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, size: 16),
                              tooltip: 'Cancel download',
                              onPressed: () => _cancelDownload(model),
                            ),
                          ],
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.download, size: 16),
                          onPressed: () => _downloadModel(model),
                          tooltip: 'Download model',
                        ),
                    ],
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 8),
                    Text(
                      model.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.settings, size: 14),
                          label: const Text('Settings'),
                          onPressed: _toggleModelSettings,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (isDownloading) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: downloadProgress,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Downloading: ${(downloadProgress! * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModelSettings() {
    if (_selectedModel == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showModelSettings = false),
              ),
              Text(
                'Model Settings',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            _selectedModel!.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            _selectedModel!.provider,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _selectedModel!.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            'Generation Parameters',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 8),

          // Temperature slider
          Row(
            children: [
              const SizedBox(width: 16),
              const Expanded(child: Text('Temperature')),
              Text(
                (_selectedModel!.parameters['temperature'] as double)
                    .toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: _selectedModel!.parameters['temperature'] as double,
            min: 0.0,
            max: 2.0,
            divisions: 20,
            label: (_selectedModel!.parameters['temperature'] as double)
                .toStringAsFixed(1),
            onChanged: (value) {
              setState(() {
                _selectedModel = AIModel(
                  id: _selectedModel!.id,
                  name: _selectedModel!.name,
                  provider: _selectedModel!.provider,
                  description: _selectedModel!.description,
                  parameterCount: _selectedModel!.parameterCount,
                  size: _selectedModel!.size,
                  isLocal: _selectedModel!.isLocal,
                  isInstalled: _selectedModel!.isInstalled,
                  downloadProgress: _selectedModel!.downloadProgress,
                  localPath: _selectedModel!.localPath,
                  parameters: {
                    ..._selectedModel!.parameters,
                    'temperature': value,
                  },
                );
              });
            },
          ),

          const SizedBox(height: 8),

          // Top-p slider
          Row(
            children: [
              const SizedBox(width: 16),
              const Expanded(child: Text('Top P')),
              Text(
                (_selectedModel!.parameters['top_p'] as double).toStringAsFixed(
                  1,
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: _selectedModel!.parameters['top_p'] as double,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: (_selectedModel!.parameters['top_p'] as double)
                .toStringAsFixed(1),
            onChanged: (value) {
              setState(() {
                _selectedModel = AIModel(
                  id: _selectedModel!.id,
                  name: _selectedModel!.name,
                  provider: _selectedModel!.provider,
                  description: _selectedModel!.description,
                  parameterCount: _selectedModel!.parameterCount,
                  size: _selectedModel!.size,
                  isLocal: _selectedModel!.isLocal,
                  isInstalled: _selectedModel!.isInstalled,
                  downloadProgress: _selectedModel!.downloadProgress,
                  localPath: _selectedModel!.localPath,
                  parameters: {..._selectedModel!.parameters, 'top_p': value},
                );
              });
            },
          ),

          const SizedBox(height: 8),

          // Max tokens
          Row(
            children: [
              const SizedBox(width: 16),
              const Expanded(child: Text('Max Tokens')),
              Text(
                (_selectedModel!.parameters['max_tokens'] as int).toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: (_selectedModel!.parameters['max_tokens'] as int).toDouble(),
            min: 256,
            max: 4096,
            divisions: 15,
            label: (_selectedModel!.parameters['max_tokens'] as int).toString(),
            onChanged: (value) {
              setState(() {
                _selectedModel = AIModel(
                  id: _selectedModel!.id,
                  name: _selectedModel!.name,
                  provider: _selectedModel!.provider,
                  description: _selectedModel!.description,
                  parameterCount: _selectedModel!.parameterCount,
                  size: _selectedModel!.size,
                  isLocal: _selectedModel!.isLocal,
                  isInstalled: _selectedModel!.isInstalled,
                  downloadProgress: _selectedModel!.downloadProgress,
                  localPath: _selectedModel!.localPath,
                  parameters: {
                    ..._selectedModel!.parameters,
                    'max_tokens': value.toInt(),
                  },
                );
              });
            },
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Advanced model actions
          Text('Model Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reset Parameters'),
            dense: true,
            onTap: () {
              // Reset model parameters to default
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Parameters reset to defaults')),
              );
            },
          ),

          if (_selectedModel!.isInstalled)
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Remove Model', style: TextStyle(color: Colors.red)),
              dense: true,
              onTap: () => _removeModel(_selectedModel!),
            ),

          const SizedBox(height: 16),

          OutlinedButton(
            onPressed: () {
              setState(() {
                _showModelSettings = false;
              });
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBouncingDot(0),
        _buildBouncingDot(100),
        _buildBouncingDot(200),
      ],
    );
  }

  Widget _buildBouncingDot(int delay) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      builder: (context, double value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 8,
          width: 8,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          transform:
              Transform.translate(
                offset: Offset(0, -4 * sin(value * 2 * pi)),
              ).transform,
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUserMessage = message.isUserMessage;
    final bubbleColor =
        isUserMessage
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[200];

    final textColor =
        isUserMessage
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomRight: isUserMessage ? const Radius.circular(0) : null,
              bottomLeft: !isUserMessage ? const Radius.circular(0) : null,
            ),
          ),
          child:
              message.isTyping
                  ? _buildTypingIndicator()
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message.text, style: TextStyle(color: textColor)),
                      const SizedBox(height: 4),
                      Text(
                        '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarExpanded ? 320 : 60,
            child: Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              elevation: 2,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: _isSidebarExpanded ? 16 : 8,
                    ),
                    title:
                        _isSidebarExpanded
                            ? const Text(
                              'Models',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )
                            : null,
                    leading: IconButton(
                      icon: Icon(
                        _isSidebarExpanded
                            ? Icons.chevron_left
                            : Icons.chevron_right,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSidebarExpanded = !_isSidebarExpanded;
                          if (!_isSidebarExpanded) {
                            _showModelSettings = false;
                          }
                        });
                      },
                    ),
                  ),
                  if (_isSidebarExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.model_training,
                              color:
                                  _showChatSessions
                                      ? null
                                      : Theme.of(context).colorScheme.primary,
                            ),
                            onPressed:
                                () => setState(() {
                                  _showChatSessions = false;
                                  _showModelSettings = false;
                                }),
                            tooltip: 'Models',
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.chat_bubble_outline,
                              color:
                                  _showChatSessions
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                            ),
                            onPressed:
                                () => setState(() {
                                  _showChatSessions = true;
                                  _showModelSettings = false;
                                }),
                            tooltip: 'Chats',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_showChatSessions) ...[
                      ListTile(
                        leading: Icon(Icons.add),
                        title: Text('New Chat'),
                        onTap: _createSession,
                      ),
                      if (_sessions.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No chats yet',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  icon: Icon(Icons.play_arrow),
                                  label: Text('Start Chat'),
                                  onPressed: _createSession,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView(
                            children:
                                _sessions.map((s) {
                                  return ListTile(
                                    title: Text(s.nickname),
                                    selected: s == _selectedSession,
                                    onTap: () => _selectSession(s),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit, size: 18),
                                          onPressed: () => _renameSession(s),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, size: 18),
                                          onPressed: () => _deleteSession(s),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _modelSearchController,
                          decoration: InputDecoration(
                            hintText: 'Search models...',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                            filled: true,
                            fillColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'all', label: Text('All')),
                            ButtonSegment(
                              value: 'ollama',
                              label: Text('Ollama'),
                            ),
                            ButtonSegment(value: 'local', label: Text('Local')),
                          ],
                          selected: {_modelFilter},
                          onSelectionChanged:
                              (s) => setState(() => _modelFilter = s.first),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child:
                            _showModelSettings && _selectedModel != null
                                ? _buildModelSettings()
                                : _buildModelList(),
                      ),
                      // bottom actions…
                    ],

                    // Bottom actions for sidebar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.upload_file, size: 16),
                              label: const Text('Load GGUF'),
                              onPressed: _showLoadModelDialog,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.auto_fix_high, size: 16),
                              label: const Text('Fine-tune'),
                              onPressed: () {
                                // Will be implemented in Phase 3
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Fine-tuning coming in Phase 3',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.model_training),
                            onPressed: () {
                              setState(() {
                                _isSidebarExpanded = true;
                              });
                            },
                            tooltip: 'Models',
                          ),
                          const SizedBox(height: 8),
                          IconButton(
                            icon: const Icon(Icons.upload_file),
                            onPressed: () {
                              setState(() {
                                _isSidebarExpanded = true;
                                _showLoadModelDialog();
                              });
                            },
                            tooltip: 'Load GGUF Model',
                          ),
                          const SizedBox(height: 8),
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () {
                              setState(() {
                                _isSidebarExpanded = true;
                                if (_selectedModel != null) {
                                  _showModelSettings = true;
                                }
                              });
                            },
                            tooltip: 'Settings',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Chat Area
          Expanded(
            child: Column(
              children: [
                // Enhanced Chat header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.smart_toy),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Assistant',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedModel != null)
                            Text(
                              _selectedModel!.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      // Enhanced model selection indicator
                      if (_selectedModel != null)
                        ActionChip(
                          avatar: Icon(
                            _selectedModel!.isLocal
                                ? Icons.folder
                                : Icons.cloud,
                            size: 16,
                          ),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_selectedModel!.provider),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.settings,
                                size: 16,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                          backgroundColor:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          onPressed: () {
                            setState(() {
                              _isSidebarExpanded = true;
                              _showModelSettings = true;
                            });
                          },
                        ),
                    ],
                  ),
                ),

                // Chat messages area
                if (_selectedSession != null)
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      itemCount:
                          (_selectedSession?.messages.length ?? 0) +
                          (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == (_selectedSession?.messages.length ?? 0)) {
                          return _buildTypingIndicator();
                        }
                        return _buildMessageBubble(
                          _selectedSession!.messages[index],
                        );
                      },
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat,
                            size: 72,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Welcome! Start a chat to begin.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _createSession,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text('Start Chat'),
                          ),
                        ],
                      ),
                    ),
                  ),

                // … then the input-area Container follows …

                // Input area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: KeyboardListener(
                          onKeyEvent: (KeyEvent event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.enter) {
                              if (HardwareKeyboard.instance.isShiftPressed) {
                                final text = _messageController.text;
                                final sel = _messageController.selection;
                                final newText = text.replaceRange(
                                  sel.start,
                                  sel.end,
                                  '\n',
                                );
                                _messageController.text = newText;
                                _messageController
                                    .selection = TextSelection.collapsed(
                                  offset: sel.start + 1,
                                );
                              } else {
                                _sendMessage();
                              }
                            }
                          },
                          focusNode: _messageFocusNode,
                          child: TextField(
                            controller: _messageController,
                            textInputAction: TextInputAction.none,
                            minLines: 1,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText:
                                  'Message ${_selectedModel?.name ?? 'AI Assistant'}...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withAlpha(0x80),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.mic),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Voice input coming in a future phase',
                                      ),
                                    ),
                                  );
                                },
                                tooltip: 'Voice input',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
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
