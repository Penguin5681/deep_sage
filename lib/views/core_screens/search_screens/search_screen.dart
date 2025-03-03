import 'package:deep_sage/core/config/api_config/suggestion_service.dart';
import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/core/config/helpers/debouncer.dart';
import 'package:deep_sage/views/core_screens/search_screens/search_category_screens/category_all.dart';
import 'package:deep_sage/widgets/source_dropdown.dart';
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

  String _getSourceParams() {
    switch (selectedSource) {
      case 'Hugging Face':
        return 'huggingface';
      case 'Kaggle':
        return 'kaggle';
      default:
        return 'all';
    }
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final results = await _suggestionService.getSuggestions(
        query: query,
        source: _getSourceParams(),
        limit: 5,
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

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox =
        _textFieldKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    var isDarkMode = Theme.of(context).brightness == Brightness.dark;
    void openDatasetCard() {
      /// details to show
      /// Source: kaggle datasets || hugging face datasets
      /// Dataset Name
      /// Dataset Description
      /// Two buttons: Download and import
      /// Dataset Size: both compressed and uncompressed
      /// Name of the owner / author
      /// Available Configs (Variants) (only for hugging face)
      /// What Api calls to make?

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 300,
              height: MediaQuery.of(context).size.height - 200,
              child: Container(
                decoration: BoxDecoration(
                  // dataset card background
                  color: isDarkMode ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
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
                                    AppIcons.huggingFaceLogo,
                                    width: 22,
                                    height: 22,
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text('Hugging Face Datasets'),
                                  // the dataset title
                                  Text(
                                    'SQUAD - Stanford Question Answering Dataset',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    'Stanford Question Answering Dataset (SQuAD) is a reading comprehension dataset, consisting of questions posed by crowdworkers on a set of Wikipedia articles.Stanford Question Answering Dataset (SQuAD) is a reading comprehension dataset, consisting of questions posed by crowdworkers on a set of Wikipedia articles.',
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
                                  Container(
                                    decoration: BoxDecoration(),
                                    child: Row(
                                      children: [
                                        // Icon Container
                                        Container(
                                          decoration: BoxDecoration(
                                            color:
                                                isDarkMode
                                                    ? Colors.grey.shade300
                                                    : Colors.grey.shade600,
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
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
                                        ),
                                        const SizedBox(width: 12.0),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Dataset Size'),
                                            const Text(
                                              '33.5 MB (compressed), 98.2 MB (uncompressed)',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  Row(
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Owner'),
                                          const Text('Dangerous Larry'),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // show configs here
                                  const SizedBox(height: 16.0),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Available Configs',
                                        style: TextStyle(
                                          fontSize: 22.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

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
                          onPanDown: (_) {
                            controller.text = suggestion.name;
                            openDatasetCard();
                            setState(() {
                              _suggestions = [];
                            });
                            _removeOverlay();
                            searchFocusNode.unfocus();
                          },
                          child: ListTile(
                            title: Text(
                              suggestion.name,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              suggestion.source == 'huggingface'
                                  ? 'Hugging Face'
                                  : 'Kaggle',
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
                  Expanded(
                    flex: 1,
                    child: SourceDropdown(
                      onSelected: () => searchFocusNode.requestFocus(),
                      onValueChanged: (value) {
                        setState(() {
                          selectedSource = value;
                        });
                        if (controller.text.length >= 2) {
                          _fetchSuggestions(controller.text);
                        }
                        debugPrint(selectedSource);
                      },
                    ),
                  ),
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
              children: const [
                CategoryAll(),
                Center(child: Text('Screen 2')),
                Center(child: Text('Screen 3')),
                Center(child: Text('Screen 4')),
                Center(child: Text('Screen 5')),
                Center(child: Text('Screen 6')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
