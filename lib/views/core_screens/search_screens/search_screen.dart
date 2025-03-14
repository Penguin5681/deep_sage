import 'dart:async';

import 'package:deep_sage/core/config/api_config/kaggle_dataset_info.dart';
import 'package:deep_sage/core/config/api_config/suggestion_service.dart';
import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/core/config/helpers/debouncer.dart';
import 'package:deep_sage/core/models/download_item.dart';
import 'package:deep_sage/core/services/download_overlay_service.dart';
import 'package:deep_sage/views/core_screens/search_screens/search_category_screens/category_all.dart';
import 'package:deep_sage/views/core_screens/search_screens/search_category_screens/category_finances.dart';
import 'package:deep_sage/views/core_screens/search_screens/search_category_screens/category_health.dart';
import 'package:deep_sage/views/core_screens/search_screens/search_category_screens/category_tech.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/services/download_service.dart';

/// {@template search_screen}
/// This widget represents the main search screen of the application, allowing
/// users to search for datasets and navigate through different categories.
/// {@endtemplate}
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  /// Controls the tab view.
  late TabController tabController;

  /// Controller for the search text field.
  final TextEditingController controller = TextEditingController();

  /// Focus node for the search text field.
  final FocusNode searchFocusNode = FocusNode();

  /// Debouncer to limit the frequency of search requests.
  final Debouncer _debouncer = Debouncer(
    delayBetweenRequests: const Duration(milliseconds: 200),
  );

  /// Layer link to position the suggestion overlay.
  final LayerLink _layerLink = LayerLink();

  /// Global key for the search text field.
  final GlobalKey _textFieldKey = GlobalKey();

  /// Global key for the download icon.
  final GlobalKey _downloadIconKey = GlobalKey();

  /// Base URL based on the current environment.
  final String baseUrl =
      dotenv.env['FLUTTER_ENV'] == 'production'
          ? dotenv.env['PROD_BASE_URL']!
          : dotenv.env['DEV_BASE_URL']!;

  /// Hive box for storing API data.
  final hiveBox = Hive.box(dotenv.env['API_HIVE_BOX_NAME']!);

  /// Overlay entry for the search suggestions.
  OverlayEntry? _overlayEntry;

  /// Overlay entry for the download progress display.
  OverlayEntry? _downloadOverlayEntry;

  /// Timer for simulating download progress.
  Timer? _downloadSimulationTimer;

  /// Currently selected data source.
  String selectedSource = 'Hugging Face';

  /// List of dataset suggestions.
  List<DatasetSuggestion> _suggestions = [];

  /// List of recent download items.
  List<DownloadItem> recentDownloads = [];

  List<OverlayEntry>? _downloadEntries;

  /// Loading states
  bool _isLoading = false;
  bool _isDatasetCardLoading = false;
  bool isDownloadOverlayVisible = false;

  late SuggestionService _suggestionService;
  late String downloadPath = '';
  late DownloadService _downloadService;

  @override
  void initState() {
    super.initState();
    // Get download service from provider without subscribing to changes
    _downloadService = Provider.of<DownloadService>(context, listen: false);

    // Get overlay service for managing download overlays
    final overlayService = Provider.of<DownloadOverlayService>(
      context,
      listen: false,
    );

    // Register callback function that will be called when overlay should be shown
    overlayService.registerOverlayCallback(_showDownloadOverlay);

    // Initialize tab controller with 4 tabs for the category views
    tabController = TabController(length: 4, vsync: this);

    // Initialize suggestion service for search autocomplete functionality
    _suggestionService = SuggestionService();

    // Add listeners to track search input and focus changes
    controller.addListener(_onSearchChanged);
    searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    // Clean up all controllers and listeners to prevent memory leaks
    controller.dispose();
    tabController.dispose();
    searchFocusNode.dispose();
    _debouncer.dispose();

    // Remove any active overlays
    _removeOverlay();

    // Cancel any active download simulation timer
    _downloadSimulationTimer?.cancel();

    super.dispose();
  }

  /// Initiates the download of a dataset with the specified ID and source.
  ///
  /// This method delegates to the [_downloadService] to handle the actual download
  /// process and shows error feedback if the download fails.
  ///
  /// Parameters:
  /// - [datasetId]: The unique identifier of the dataset to download.
  /// - [source]: The source platform of the dataset (e.g., 'kaggle').
  Future<void> _startDownload(String datasetId, String source) async {
    try {
      await _downloadService.downloadDataset(
        source: source,
        datasetId: datasetId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.toString()}')),
        );
      }
    }
  }

  /// Handles search text changes and triggers suggestion retrieval.
  ///
  /// Clears suggestions if the query is too short, otherwise sets loading state
  /// and uses a debouncer to fetch suggestions after a short delay to prevent
  /// excessive API calls during typing.
  void _onSearchChanged() {
    final query = controller.text;
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      _removeOverlay();
      return;
    }
    setState(() {
      _isLoading = true;
    });
    _debouncer.run(() {
      _fetchSuggestions(query);
    });
  }

  /// Responds to search field focus changes.
  ///
  /// When focus is lost, clears suggestions and removes the overlay.
  /// When focus is gained and sufficient text is entered, fetches suggestions.
  void _onFocusChanged() {
    if (!searchFocusNode.hasFocus) {
      setState(() {
        _suggestions = [];
      });
      _removeOverlay();
    } else if (controller.text.length >= 2) {
      _fetchSuggestions(controller.text);
    }
  }

  /// Fetches dataset suggestions based on the provided query.
  ///
  /// Makes an API request to retrieve dataset suggestions matching the query
  /// and updates the UI accordingly. Shows or removes the suggestion overlay
  /// depending on the results.
  ///
  /// Parameters:
  /// - [query]: The search text to find matching datasets.
  Future<void> _fetchSuggestions(String query) async {
    try {
      final results = await _suggestionService.getSuggestions(
        query: query,
        source: 'kaggle',
        limit: 15,
      );
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
        if (_suggestions.isNotEmpty && searchFocusNode.hasFocus) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
      }
      debugPrint('Error fetching suggestions: $e');
      _removeOverlay();
    }
  }

  /// Displays the suggestion overlay.
  ///
  /// If an overlay is already visible, it updates the existing one.
  /// Otherwise, it creates and displays a new overlay with suggestions.
  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Toggles the download history overlay display.
  ///
  /// If the overlay is already visible, it removes it. Otherwise, it creates
  /// and displays a new overlay with download history information.
  /// The overlay includes a transparent barrier that dismisses the overlay
  /// when tapped.
  void _showDownloadOverlay() {
    if (isDownloadOverlayVisible) {
      _removeDownloadOverlay();
      return;
    }

    final barrierOverlay = OverlayEntry(
      builder:
          (context) => Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _removeDownloadOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
    );

    _downloadOverlayEntry = _createDownloadOverlayEntry();

    Overlay.of(context).insert(barrierOverlay);
    Overlay.of(context).insert(_downloadOverlayEntry!);

    _downloadEntries = [barrierOverlay, _downloadOverlayEntry!];
    isDownloadOverlayVisible = true;
  }

  /// Removes the download history overlay from the screen.
  ///
  /// If there are any overlay entries for the download history, they are removed
  /// and the related variables are reset to their default states.
  void _removeDownloadOverlay() {
    if (_downloadEntries != null) {
      for (final entry in _downloadEntries!) {
        entry.remove();
      }
      _downloadEntries = null;
    }
    _downloadOverlayEntry = null;
    isDownloadOverlayVisible = false;
  }

  /// Removes the search suggestion overlay from the screen.
  ///
  /// If there is an active overlay entry for search suggestions, it is removed
  /// and the related variables are reset to their default states.
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Opens a dialog displaying detailed information about a dataset.
  ///
  /// This method fetches metadata for the specified dataset from its source,
  /// displays a loading indicator while fetching, and then presents the data
  /// in a formatted dialog with options to download or import the dataset.
  ///
  /// Parameters:
  /// - [datasetId]: The unique identifier of the dataset to display.
  /// - [source]: The platform source of the dataset (e.g., 'kaggle').
  ///
  /// The dialog includes:
  /// - Dataset title and basic information
  /// - Full description
  /// - Metadata like owner, size, votes, download count
  /// - Links to the original source
  /// - Actions to download or import the dataset
  Future<void> openDatasetCard(String datasetId, String source) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    KaggleDataset? kaggleMetadata;
    setState(() {
      _isDatasetCardLoading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => showLoadingIndicator(context),
    );

    if (source case 'kaggle') {
      final KaggleDatasetInfoService kaggleDatasetInfoService =
          KaggleDatasetInfoService();
      kaggleMetadata = await kaggleDatasetInfoService
          .retrieveKaggleDatasetMetadata(datasetId);
    } else {
      debugPrint('Something bad happened');
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    setState(() {
      _isDatasetCardLoading = false;
    });

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String title = '';
        String description = '';
        String owner = '';
        String size = '';
        String url = '';
        String lastUpdated = '';
        String id = '';
        int votes = 0;
        int downloadCount = 0;

        if (source == 'kaggle' && kaggleMetadata != null) {
          title = kaggleMetadata.title;
          description = kaggleMetadata.description;
          owner = kaggleMetadata.owner;
          size = kaggleMetadata.size;
          votes = kaggleMetadata.voteCount;
          url = kaggleMetadata.url;
          lastUpdated = kaggleMetadata.lastUpdated;
          downloadCount = kaggleMetadata.downloadCount;
          id = kaggleMetadata.id;
        }

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 150,
            vertical: 50,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Row(
                    children: [
                      Image.asset(AppIcons.kaggleLogo, width: 28, height: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kaggle Dataset',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDarkMode
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade700,
                              ),
                            ),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'ID: $id',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                    ),
                  ),
                ),

                const Divider(height: 32),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  isDarkMode
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                            ),
                          ),
                          child:
                              description.isEmpty
                                  ? Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color:
                                            isDarkMode
                                                ? Colors.grey.shade500
                                                : Colors.grey.shade600,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'No description available',
                                        style: TextStyle(
                                          color:
                                              isDarkMode
                                                  ? Colors.grey.shade500
                                                  : Colors.grey.shade600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  )
                                  : Text(
                                    description,
                                    style: TextStyle(
                                      color:
                                          isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'Dataset Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildInfoItem(
                              isDarkMode,
                              Icons.person,
                              'Owner',
                              owner,
                            ),
                            _buildInfoItem(
                              isDarkMode,
                              Icons.folder,
                              'Size',
                              size,
                            ),
                            _buildInfoItem(
                              isDarkMode,
                              Icons.thumb_up,
                              'Votes',
                              votes.toString(),
                            ),
                            _buildInfoItem(
                              isDarkMode,
                              Icons.download,
                              'Downloads',
                              NumberFormat.compact().format(downloadCount),
                            ),
                            _buildInfoItem(
                              isDarkMode,
                              Icons.update,
                              'Last Updated',
                              lastUpdated,
                            ),
                            _buildInfoItem(
                              isDarkMode,
                              Icons.link,
                              'URL',
                              'View on Kaggle',
                              isLink: true,
                              linkUrl: url,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.black : Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _startDownload(id, 'kaggle');
                          _showDownloadOverlay();
                        },
                        icon: const Icon(Icons.cloud_download),
                        label: const Text('Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                          foregroundColor:
                              isDarkMode ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add_chart),
                        label: const Text('Import'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds a single item for displaying information in a grid.
  ///
  /// This widget creates a container that shows a label and its value, optionally
  /// with a clickable link. The appearance is adapted based on whether the app
  /// is in dark mode or light mode.
  ///
  /// Parameters:
  /// - [isDarkMode]: Determines if the dark mode is active.
  /// - [icon]: The icon to display next to the label.
  /// - [label]: The text label describing the value.
  /// - [value]: The text value associated with the label.
  /// - [isLink]: If true, the value will be displayed as a link.
  /// - [linkUrl]: The URL to open if the value is a link.
  ///
  /// The item includes:
  /// - A container with a background color based on the mode (dark/light).
  /// - An icon with colors based on the mode.
  /// - A label text with appropriate styling.
  /// - If `isLink` is true, the value is displayed as a clickable link that,
  ///   when tapped, attempts to open the specified `linkUrl`.
  /// - If `isLink` is false, the value is displayed as regular text.
  ///
  Widget _buildInfoItem(
    bool isDarkMode,
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
    String? linkUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade700 : Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        isDarkMode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                  ),
                ),
                if (isLink)
                  InkWell(
                    onTap:
                        linkUrl != null
                            ? () async {
                              if (!await launchUrl(Uri.parse(linkUrl))) {
                                throw Exception('Unable to launch url!');
                              }
                              debugPrint('Launch URL: $linkUrl');
                            }
                            : null,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Displays a loading indicator dialog.
  ///
  /// This function creates and returns a dialog containing a circular
  /// progress indicator and a 'Loading...' text, styled according to the
  /// current theme (dark or light).
  ///
  Widget showLoadingIndicator(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: isDarkMode ? Colors.white : Colors.blue.shade600,
              ),
              const SizedBox(height: 16.0),
              Text(
                'Loading...',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Creates and configures an overlay entry for displaying search suggestions.
  ///
  /// This function constructs an overlay entry that appears below the search
  /// text field, displaying a list of dataset suggestions. The overlay is
  /// positioned dynamically relative to the text field using a LayerLink.
  /// The suggestions are interactive and allow direct selection.
  ///
  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox =
        _textFieldKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    var isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return OverlayEntry(
      builder:
          (context) => Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 5.0,
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, size.height + 5.0),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8.0),
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onPanDown: ((_) async {
                            controller.text = suggestion.name;
                            _isDatasetCardLoading = true;
                            debugPrint(_isDatasetCardLoading.toString());
                            debugPrint(suggestion.source);
                            await openDatasetCard(
                              suggestion.name,
                              suggestion.source,
                            );
                            debugPrint(suggestion.name);
                            setState(() {
                              _isDatasetCardLoading = false;
                              debugPrint(_isDatasetCardLoading.toString());
                              _suggestions = [];
                            });
                            debugPrint('Outside of setState() {}');
                            debugPrint(_isDatasetCardLoading.toString());
                            _removeOverlay();
                            searchFocusNode.unfocus();
                          }),
                          child: ListTile(
                            title: Text(
                              suggestion.name,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              'Kaggle',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isDarkMode ? Colors.grey[300] : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
    );
  }

  /// Creates an overlay entry for displaying the download history.
  ///
  /// This function builds an overlay entry that appears near the download icon,
  /// showing a list of current and recent downloads. It includes options to
  /// view download details, clear completed downloads, and navigate to a full
  /// download history view. The styling adapts to the current theme.
  ///
  OverlayEntry _createDownloadOverlayEntry() {
    RenderBox renderBox =
        _downloadIconKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return OverlayEntry(
      builder:
          (context) => Positioned(
            right: 35.0,
            top: offset.dy + size.height,
            width: 350,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8.0),
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Downloads',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.clear_all,
                                color:
                                    isDarkMode
                                        ? Colors.white70
                                        : Colors.grey[700],
                              ),
                              onPressed: () {
                                _downloadService.clearCompletedDownloads();
                              },
                              tooltip: 'Clear completed',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 32,
                                height: 32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 350),
                    child: Consumer<DownloadService>(
                      builder: (context, downloadService, child) {
                        final downloads = downloadService.downloads;

                        if (downloads.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'No recent downloads',
                                style: TextStyle(
                                  color:
                                      isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[700],
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: downloads.length,
                          separatorBuilder:
                              (context, index) => Divider(
                                height: 1,
                                color:
                                    isDarkMode
                                        ? Colors.grey[700]
                                        : Colors.grey[300],
                              ),
                          itemBuilder: (context, index) {
                            final download = downloads[index];
                            return _buildDownloadItem(download, isDarkMode);
                          },
                        );
                      },
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _removeDownloadOverlay();
                      // TODO: create a full download history screen
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color:
                                isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'View full download history',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  /// Determines the appropriate icon based on the file name's extension.
  ///
  /// This function examines the file name's extension and returns the
  /// corresponding [IconData] object to represent the file type visually.
  ///
  /// - If the file ends with '.csv', it returns [Icons.table_chart] to indicate a
  ///   spreadsheet or tabular data file.
  /// - If the file ends with '.json', it returns [Icons.data_object] to represent
  ///   a JSON data file.
  /// - If the file ends with '.zip', it returns [Icons.folder_zip] to represent
  ///   a compressed file archive.
  /// - For any other file extension, it defaults to [Icons.insert_drive_file] to
  ///   represent a generic file.
  IconData _getFileIcon(String fileName) {
    if (fileName.endsWith('.csv')) {
      return Icons.table_chart;
    } else if (fileName.endsWith('.json')) {
      return Icons.data_object;
    } else if (fileName.endsWith('.zip')) {
      return Icons.folder_zip;
    } else {
      return Icons.insert_drive_file;
    }
  }

  /// Builds a widget that represents a single download item in the download list.
  ///
  /// This function creates a [Padding] widget that contains a [Row] to display
  /// information about a downloaded or in-progress download item. The layout
  /// includes:
  /// - An icon representing the file type, determined by [_getFileIcon].
  /// - The name of the file.
  /// - The status of the download (complete, queued, or in progress).
  /// - A progress bar if the download is in progress.
  /// - Size and download speed information.
  /// - An [IconButton] to allow actions like canceling or viewing details,
  ///   depending on the download status.
  ///
  /// Parameters:
  /// - [download]: The [DownloadItem] model containing the download's data.
  /// - [isDarkMode]: A boolean indicating whether the app is in dark mode.
  ///
  /// The download status is displayed as:
  /// - 'Complete' with the file size if [download.isComplete] is true.
  /// - 'Queued for download' if [download.size] is 'Queued'.
  /// - A progress bar with percentage, size, and download speed if the
  ///   download is in progress.
  ///
  /// The [IconButton] displays either:
  /// - [Icons.more_vert] for completed downloads, which, when pressed,
  ///   calls [_showDownloadOptions].
  /// - [Icons.close] for ongoing downloads, allowing cancellation via
  ///   [_downloadService.cancelDownload].
  Widget _buildDownloadItem(DownloadItem download, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(
            _getFileIcon(download.name),
            size: 24,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  download.name,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (download.isComplete)
                  Text(
                    '${download.size} • Complete',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      fontSize: 12,
                    ),
                  )
                else if (download.size == 'Queued')
                  Text(
                    'Queued for download',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: download.progress,
                              backgroundColor:
                                  isDarkMode
                                      ? Colors.grey[700]
                                      : Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(download.progress * 100).toInt()}%',
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            download.size,
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            download.downloadSpeed,
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            icon:
                download.isComplete
                    ? Icon(
                      Icons.more_vert,
                      size: 20,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    )
                    : Icon(Icons.close, size: 20, color: Colors.red[400]),
            onPressed:
                () =>
                    download.isComplete
                        ? _showDownloadOptions(download)
                        : _downloadService.cancelDownload(download.datasetId),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          ),
        ],
      ),
    );
  }

  void _showDownloadOptions(DownloadItem download) {}

  /// Handles search initiation and updates the search text field.
  ///
  /// This method is called when a search is initiated, setting the text of
  /// the search field to the given query and requesting focus for it.
  void handleSearch(String query) {
    setState(() {
      controller.text = query;
    });
    searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    var isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 35.0, top: 35.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Home',
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                    const Text('  >  ', style: TextStyle(fontSize: 16.0)),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Search',
                          style: TextStyle(fontSize: 16.0),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 35.0),
                  child: IconButton(
                    key: _downloadIconKey,
                    onPressed: _showDownloadOverlay,
                    icon: Icon(Icons.download, color: Color(0xff3091e7)),
                    tooltip: 'View your current downloads',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 35.0, top: 25.0, right: 35.0),
            child: SizedBox(
              height: 70.0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4,
                    child: CompositedTransformTarget(
                      link: _layerLink,
                      child: Container(
                        key: _textFieldKey,
                        child: TextField(
                          controller: controller,
                          focusNode: searchFocusNode,
                          onSubmitted: (value) {
                            _removeOverlay();
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            suffix:
                                _isLoading
                                    ? Container(
                                      width: 24,
                                      height: 24,
                                      padding: const EdgeInsets.all(6.0),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            hintText:
                                'Search Datasets by name, type or category',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                ],
              ),
            ),
          ),
          TabBar(
            padding: const EdgeInsets.only(right: 650.0),
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: isDarkMode ? Colors.white : Colors.black,
            unselectedLabelColor: isDarkMode ? Colors.grey : Colors.grey,
            indicatorColor: isDarkMode ? Colors.white : Colors.black,
            indicatorAnimation: TabIndicatorAnimation.elastic,
            controller: tabController,
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Finances'),
              Tab(text: 'Technology'),
              Tab(text: 'Healthcare'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                // Added the required categories
                CategoryAll(onSearch: handleSearch),
                CategoryFinances(onSearch: handleSearch),
                CategoryTechnology(onSearch: handleSearch),
                CategoryHealth(onSearch: handleSearch),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
