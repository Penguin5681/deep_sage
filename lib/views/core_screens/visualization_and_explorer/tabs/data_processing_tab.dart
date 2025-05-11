import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:deep_sage/core/services/core_services/data_tuning_services/data_tuning_service.dart';

class DataProcessingTab extends StatefulWidget {
  final String? currentDataset;
  final String? currentDatasetPath;
  final String? currentDatasetType;

  const DataProcessingTab({
    super.key,
    this.currentDataset,
    this.currentDatasetPath,
    this.currentDatasetType,
  });

  @override
  State<DataProcessingTab> createState() => _DataProcessingTabState();
}

class _DataProcessingTabState extends State<DataProcessingTab> {
  final DataTuningService _dataTuningService = DataTuningService();
  bool _isLoading = false;
  String? _fileId;
  String? _errorMessage;
  String? _successMessage;
  final TextEditingController _promptTemplateController =
      TextEditingController();
  final TextEditingController _responseTemplateController =
      TextEditingController();

  bool get _hasValidDataset =>
      widget.currentDataset != null &&
      widget.currentDatasetPath != null &&
      widget.currentDatasetType?.toLowerCase() == 'csv';

  @override
  void dispose() {
    _promptTemplateController.dispose();
    _responseTemplateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildDatasetIndicator(),
          Expanded(child: _buildProcessingContent()),
          if (_isLoading) const LinearProgressIndicator(),
          if (_errorMessage != null || _successMessage != null)
            _buildMessageBanner(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Processing',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Prepare your data for fine-tuning and analysis',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (_hasValidDataset)
            ElevatedButton.icon(
              onPressed: _uploadCsvFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.tertiary,
                foregroundColor: Theme.of(context).colorScheme.onTertiary,
                elevation: 3,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDatasetIndicator() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: _getIndicatorColor(isDarkMode),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                widget.currentDataset == null
                    ? Colors.grey.shade400
                    : Colors.blue.shade400,
          ),
        ),
        child: Row(
          children: [
            Icon(
              widget.currentDataset == null
                  ? Icons.info_outline
                  : _getFileIcon(widget.currentDatasetType ?? ''),
              color:
                  widget.currentDataset == null
                      ? Colors.amber
                      : _getFileColor(widget.currentDatasetType ?? ''),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child:
                  widget.currentDataset == null
                      ? const Text('No dataset selected')
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Working with: ${widget.currentDataset}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (widget.currentDatasetPath != null)
                            Text(
                              _getDisplayPath(widget.currentDatasetPath!),
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    isDarkMode
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingContent() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAutoPromptSection(),
            const Divider(height: 32),
            _buildCustomTemplateSection(),
            const Divider(height: 32),
            _buildDownloadSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoPromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Auto-Prompt Generation',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Generate JSONL with automatically created prompts',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _fileId != null ? _generateAutoPrompt : null,
          icon: const Icon(Icons.auto_awesome),
          label: const Text(
            'Generate Auto-Prompted JSONL',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.blue.shade600, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            foregroundColor: Colors.blue.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.disabled)) {
                return null;
              }
              return null;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTemplateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Custom Template',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Create JSONL with your own templates',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _promptTemplateController,
                decoration: const InputDecoration(
                  helperText:
                      'Use single curly braces \\{column_name\\} to reference CSV columns',
                  helperMaxLines: 2,
                  labelText: 'Prompt Template',
                  hintText: 'E.g., "Summarize: \\{column_name\\}"',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 3,
                enabled: _fileId != null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _responseTemplateController,
                decoration: const InputDecoration(
                  helperText:
                      'Use single curly braces \\{column_name\\} to reference CSV columns',
                  helperMaxLines: 2,
                  labelText: 'Response Template',
                  hintText: 'E.g., "\\{summary_column\\}"',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 3,
                enabled: _fileId != null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed:
              (_fileId != null &&
                      _promptTemplateController.text.isNotEmpty &&
                      _responseTemplateController.text.isNotEmpty)
                  ? _generateCustomTemplate
                  : null,
          icon: const Icon(Icons.design_services),
          label: const Text('Generate Template JSONL'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.blue.shade600, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            foregroundColor: Colors.blue.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.disabled)) {
                return null;
              }
              return null;
            }),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _fileId != null ? _suggestAITemplates : null,
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('Suggest AI Templates'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.blue.shade600, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            foregroundColor: Colors.blue.shade600,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>((
              Set<WidgetState> states,
            ) {
              if (states.contains(WidgetState.disabled)) {
                return null;
              }
              return null;
            }),
          ),
        ),
      ],
    );
  }

  Future<void> _suggestAITemplates() async {
    if (_fileId == null) {
      _setErrorMessage('Please upload a CSV file first');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Call the service to get AI-suggested templates
      final result = await _dataTuningService.suggestAITemplates(_fileId!);

      if (result['status'] != 'success' || result['templates'] == null) {
        throw Exception('Invalid response from server');
      }

      final templates = List<Map<String, dynamic>>.from(result['templates']);

      if (templates.isEmpty) {
        _setSuccessMessage('No templates could be generated. Try again.');
        return;
      }

      // Show dialog with template options
      final selected = await _showTemplateSelectionDialog(templates);

      // If a template was selected, set it to the text fields
      if (selected != null) {
        setState(() {
          _promptTemplateController.text = selected['prompt_template'];
          _responseTemplateController.text = selected['response_template'];
        });
        _setSuccessMessage('AI template applied successfully');
      }
    } catch (e) {
      _setErrorMessage('Error suggesting templates: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _showTemplateSelectionDialog(
    List<Map<String, dynamic>> templates,
  ) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose a Template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  templates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final template = entry.value;
                    return _buildTemplateCard(
                      index + 1,
                      template['prompt_template'],
                      template['response_template'],
                      () {
                        Navigator.of(context).pop(template);
                      },
                    );
                  }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTemplateCard(
    int number,
    String promptTemplate,
    String responseTemplate,
    VoidCallback onSelect,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  radius: 12,
                  child: Text(
                    number.toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Template Option $number',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Prompt:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(promptTemplate),
            ),
            const SizedBox(height: 8),
            const Text(
              'Response:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(responseTemplate),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onSelect,
                child: const Text('Use This Template'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Download Generated Files',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: _fileId != null ? () => _downloadJsonl('auto') : null,
              icon: const Icon(Icons.download),
              label: const Text('Auto JSONL'),
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed:
                  _fileId != null ? () => _downloadJsonl('template') : null,
              icon: const Icon(Icons.download),
              label: const Text('Custom JSONL'),
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageBanner() {
    final isError = _errorMessage != null;
    final message = isError ? _errorMessage! : _successMessage!;
    final color = isError ? Colors.red : Colors.green;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: color,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(color: color))),
          ],
        ),
      ),
    );
  }

  Color _getIndicatorColor(bool isDarkMode) {
    if (widget.currentDataset == null) {
      return isDarkMode
          ? Colors.grey.shade800.withValues(alpha: 0.2)
          : Colors.grey.shade200;
    } else {
      return isDarkMode
          ? Colors.blue.shade900.withValues(alpha: 0.2)
          : Colors.blue.shade50;
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'csv':
        return Icons.table_chart;
      case 'json':
        return Icons.data_object;
      case 'xlsx':
        return Icons.grid_on;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'csv':
        return Colors.green;
      case 'json':
        return Colors.orange;
      case 'xlsx':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getDisplayPath(String path) {
    if (path.length <= 40) return path;

    final pathParts = path.split('/');
    if (pathParts.length <= 3) return path;

    return '.../${pathParts[pathParts.length - 2]}/${pathParts.last}';
  }

  // API Actions
  Future<void> _uploadCsvFile() async {
    if (widget.currentDatasetPath == null) {
      _setErrorMessage('No dataset selected');
      return;
    }

    final file = File(widget.currentDatasetPath!);
    if (!await file.exists()) {
      _setErrorMessage('File does not exist');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await _dataTuningService.uploadCsv(file);
      _fileId = result['file_id'];
      _setSuccessMessage('CSV file uploaded successfully');
    } catch (e) {
      _setErrorMessage('Error uploading CSV: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateAutoPrompt() async {
    if (_fileId == null) {
      _setErrorMessage('Please upload a CSV file first');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _dataTuningService.generateAutoPromptJsonl(_fileId!);
      _setSuccessMessage('Auto-prompted JSONL generated successfully');
    } catch (e) {
      _setErrorMessage('Error generating auto-prompted JSONL: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateCustomTemplate() async {
    if (_fileId == null) {
      _setErrorMessage('Please upload a CSV file first');
      return;
    }

    if (_promptTemplateController.text.isEmpty ||
        _responseTemplateController.text.isEmpty) {
      _setErrorMessage('Please provide both prompt and response templates');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _dataTuningService.generateTemplateJsonl(
        _fileId!,
        _promptTemplateController.text,
        _responseTemplateController.text,
      );
      _setSuccessMessage('Custom template JSONL generated successfully');
    } catch (e) {
      _setErrorMessage(
        'Error generating custom template JSONL: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadJsonl(String type) async {
    if (_fileId == null) {
      _setErrorMessage('No file available for download');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await _dataTuningService.downloadJsonl(_fileId!, type);

      final result = await FilePicker.platform.getDirectoryPath();
      if (result == null) {
        _setErrorMessage('Download cancelled');
        setState(() => _isLoading = false);
        return;
      }

      final String fileName = '${_fileId!}_$type.jsonl';
      final String filePath = path.join(result, fileName);
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      _setSuccessMessage('JSONL downloaded to $filePath');
    } catch (e) {
      _setErrorMessage('Error downloading JSONL: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
      _successMessage = null;
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  void _setSuccessMessage(String message) {
    setState(() {
      _successMessage = message;
      _errorMessage = null;
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _successMessage = null;
        });
      }
    });
  }
}
