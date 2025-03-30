import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/download_overlay_service.dart';
import '../core/services/download_service.dart';

class PopularDatasetCard extends StatefulWidget {
  /// The title of the dataset.
  final String title;

  /// The time when the dataset was added.
  final String addedTime;

  /// The file type of the dataset.
  final String fileType;

  /// The size of the dataset file.
  final String fileSize;

  /// The unique identifier of the dataset.
  final String datasetId;

  /// Creates a [PopularDatasetCard] widget.
  ///
  /// This widget displays information about a popular dataset, including its
  /// title, added time, file type, file size, and a download button.
  ///
  /// The [title], [addedTime], [fileType], [fileSize], and [datasetId]
  /// arguments must not be null.
  const PopularDatasetCard({
    super.key,
    required this.title,
    required this.addedTime,
    required this.fileType,
    required this.fileSize,
    required this.datasetId,
  });

  @override
  State<PopularDatasetCard> createState() =>
      _PopularDatasetCardState();
}

class _PopularDatasetCardState extends State<PopularDatasetCard> {
  /// Indicates whether the card is currently being hovered over.
  bool isHovered = false;

  /// Builds the UI for the popular dataset card.

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    IconData fileTypeIcon = Icons.description_outlined;
    Color fileTypeColor = colorScheme.primary;

    switch (widget.fileType.toLowerCase()) {
      case 'csv':
        fileTypeIcon = Icons.table_chart_outlined;
        fileTypeColor = Colors.green.shade700;
        break;
      case 'json':
        fileTypeIcon = Icons.data_object_outlined;
        fileTypeColor = Colors.orange.shade700;
        break;
      case 'xlsx':
      case 'xls':
        fileTypeIcon = Icons.table_rows_outlined;
        fileTypeColor = Colors.green.shade700;
        break;
      case 'txt':
        fileTypeIcon = Icons.text_snippet_outlined;
        fileTypeColor = Colors.blue.shade700;
        break;
      case 'zip':
        fileTypeIcon = Icons.folder_zip_outlined;
        fileTypeColor = Colors.purple.shade700;
        break;
    }

    return MouseRegion(
      /// Handles the mouse hover state.
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isHovered
              ? (isDarkMode
                  ? [
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                    ]
                  : [
                      colorScheme.surface,
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                    ])
              : (isDarkMode
                  ? [
                      colorScheme.surface.withValues(alpha: 0.3),
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ]
                  : [
                      colorScheme.surface,
                      colorScheme.surface,
                    ]),
          ),
          boxShadow: isHovered
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File type badge
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: fileTypeColor.withValues(alpha: isDarkMode ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      fileTypeIcon,
                      color: fileTypeColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Dataset title and details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Added: ${widget.addedTime}',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.insert_drive_file_outlined,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.fileType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.data_usage_outlined,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.fileSize,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Download button
                  Consumer<DownloadService>(
                    builder: (context, downloadService, _) {
                      return FilledButton.icon(
                        /// Downloads the dataset and shows the download overlay.
                        onPressed: () async {
                          await downloadService.downloadDataset(
                            source: 'kaggle',
                            datasetId: widget.datasetId,
                          );
                          if (!context.mounted) return;
                          final overlayService = Provider.of<DownloadOverlayService>(
                            context,
                            listen: false,
                          );
                          overlayService.showDownloadOverlay();
                        },
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Download'),
                        style: FilledButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  /// Capitalizes the first letter of the string.
  ///
  /// Returns a new string with the first letter capitalized.
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}