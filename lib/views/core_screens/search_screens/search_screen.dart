import 'package:deep_sage/core/config/api_config/kaggle_dataset_info.dart';
import 'package:deep_sage/core/config/api_config/suggestion_service.dart';
import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/core/config/helpers/debouncer.dart';
import 'package:deep_sage/views/core_screens/search_screens/search_category_screens/category_all.dart';
import 'package:deep_sage/views/core_screens/search_screens/search_category_screens/category_finances.dart';
import 'package:deep_sage/views/core_screens/search_screens/search_category_screens/category_gov.dart';
import 'package:deep_sage/views/core_screens/search_screens/search_category_screens/category_health.dart';
import 'package:deep_sage/views/core_screens/search_screens/search_category_screens/category_manufacture.dart';
import 'package:deep_sage/views/core_screens/search_screens/search_category_screens/category_tech.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  final TextEditingController controller = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  String selectedSource = 'Hugging Face';

  final Debouncer _debouncer = Debouncer(
    delayBetweenRequests: const Duration(milliseconds: 200),
  );
  List<DatasetSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _isDatasetCardLoading = false;
  late SuggestionService _suggestionService;

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _textFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 6, vsync: this);
    _suggestionService = SuggestionService();

    controller.addListener(_onSearchChanged);
    searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    controller.dispose();
    tabController.dispose();
    searchFocusNode.dispose();
    _debouncer.dispose();
    _removeOverlay();
    super.dispose();
  }

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

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

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
        List<String> configs = [];

        if (source == 'kaggle' && kaggleMetadata != null) {
          title = kaggleMetadata.title;
          description = kaggleMetadata.description;
          owner = kaggleMetadata.owner;
          size = kaggleMetadata.size;
          configs = [];
        }

        return Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 300,
            height: MediaQuery.of(context).size.height - 300,
            child: Container(
              decoration: BoxDecoration(
                // dataset card background
                color: isDarkMode ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 75.0,
                      right: 75.0,
                      top: 40.0,
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.0),
                        color:
                            isDarkMode
                                ? Colors.grey.shade900
                                : Colors.grey.shade300,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon Container
                          const SizedBox(height: 18.0),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset(
                                  AppIcons.kaggleLogo,
                                  width: 22,
                                  height: 22,
                                ),
                                const SizedBox(height: 8.0),
                                Text('Kaggle Datasets'),
                                // the dataset title
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24.0,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  description,
                                  maxLines: 4,
                                  softWrap: true,
                                  style: TextStyle(fontSize: 16.0),
                                ),
                                const SizedBox(height: 8.0),
                                Row(
                                  children: [
                                    // buttons
                                    ElevatedButton(
                                      onPressed: () {},
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: const Text(
                                        "Import",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10.0),
                                    OutlinedButton(
                                      onPressed: () {
                                        // onNavigate(1);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: Colors.blue.shade600,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        foregroundColor: Colors.blue.shade600,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                      ),
                                      child: const Text(
                                        "Download",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16.0),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18.0),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 76.0,
                      right: 76.0,
                      top: 16.0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(),
                      child: Row(
                        children: [
                          // Icon Container
                          source == 'kaggle'
                              ? Container(
                                decoration: BoxDecoration(
                                  color:
                                      isDarkMode
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade600,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    isDarkMode
                                        ? AppIcons.serverLight
                                        : AppIcons.serverDark,
                                    width: 15,
                                    height: 15,
                                  ),
                                ),
                              )
                              : Container(),
                          const SizedBox(width: 12.0),
                          source == 'kaggle'
                              ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Dataset Size'),
                                  Text('$size (compressed)'),
                                ],
                              )
                              : Container(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Padding(
                    padding: const EdgeInsets.only(left: 76.0, right: 76.0),
                    child: Row(
                      children: [
                        // Icon Container
                        ClipOval(
                          child: Image.asset(
                            AppIcons.larry,
                            width: 32,
                            height: 32,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [const Text('Owner'), Text(owner)],
                        ),
                      ],
                    ),
                  ),
                  // show configs here
                  const SizedBox(height: 16.0),
                  // configs here
                  source == 'huggingface' && configs.isNotEmpty
                      ? Padding(
                        padding: const EdgeInsets.only(
                          left: 76.0,
                          right: 76.0,
                          top: 16.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configurations',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8.0),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children:
                                  configs.map((config) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0,
                                        vertical: 6.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isDarkMode
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(
                                          16.0,
                                        ),
                                      ),
                                      child: Text(config),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      )
                      : Container(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {},
                    child: const Text('Home', style: TextStyle(fontSize: 16.0)),
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
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text(
                                    'Search has been completed',
                                  ),
                                  content: Text('You Searched for: $value'),
                                );
                              },
                            );
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
              Tab(text: 'Government'),
              Tab(text: 'Manufacturing'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                CategoryAll(onSearch: handleSearch),
                CategoryFinances(onSearch: handleSearch),
                CategoryTechnology(onSearch: handleSearch),
                CategoryHealthcare(onSearch: handleSearch),
                CategoryGovernment(onSearch: handleSearch),
                CategoryManufacturing(onSearch: handleSearch),
                // TODO: Pass all the filters in the respective screens
                // Center(child: Text('Screen 2')),
                // Center(child: Text('Screen 3')),
                // Center(child: Text('Screen 4')),
                // Center(child: Text('Screen 5')),
                // Center(child: Text('Screen 6')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
