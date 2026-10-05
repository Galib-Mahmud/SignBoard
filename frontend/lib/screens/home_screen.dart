import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/category_model.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/post_card.dart';
import 'filter_drawer.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenProfile;

  const HomeScreen({
    super.key,
    required this.onOpenProfile,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<CategoryModel> _categories = [];
  List<PostModel> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  String? _selectedCategory;
  String _sortOrder = 'recent'; // 'recent' or 'distance'
  double? _maxDistance;
  int _currentPage = 1;
  bool _hasMore = true;

  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _loadLocationAndData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMorePosts();
    }
  }

  Future<void> _loadLocationAndData() async {
    setState(() => _isLoading = true);

    // 1. Get user GPS location
    _userPosition = await LocationService().getCurrentLocation();

    // 2. Fetch categories
    try {
      final cats = await ApiService().getCategories();
      if (mounted) {
        setState(() => _categories = cats);
      }
    } catch (_) {}

    // 3. Fetch initial posts
    await _fetchPosts(reset: true);
  }

  Future<void> _fetchPosts({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await ApiService().getPosts(
        category: _selectedCategory,
        search: _searchController.text,
        latitude: _userPosition?.latitude,
        longitude: _userPosition?.longitude,
        sort: _sortOrder,
        maxDistance: _maxDistance,
        page: _currentPage,
      );

      final List<PostModel> fetched = result['posts'];
      if (mounted) {
        setState(() {
          if (reset) {
            _posts = fetched;
          } else {
            _posts.addAll(fetched);
          }
          _hasMore = result['next'] != null;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load posts: ${e.toString()}';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage += 1;
    await _fetchPosts(reset: false);
  }

  void _onApplyFilters({
    required String? category,
    required String sortOrder,
    required double? maxDistance,
  }) {
    setState(() {
      _selectedCategory = category;
      _sortOrder = sortOrder;
      _maxDistance = maxDistance;
    });
    _fetchPosts(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService().currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.bgCanvas,
      drawer: FilterDrawer(
        categories: _categories,
        selectedCategory: _selectedCategory,
        sortOrder: _sortOrder,
        maxDistance: _maxDistance,
        onApply: _onApplyFilters,
      ),
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        // Top Left: Filter Button (opens filter drawer)
        leading: IconButton(
          icon: const Icon(
            Icons.tune_rounded,
            color: AppTheme.primaryDark,
            size: 22,
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'Filter Categories & Distance',
        ),
        title: Row(
          children: [
            const Text(
              'SignBoard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryDark,
                letterSpacing: -0.3,
              ),
            ),
            if (_selectedCategory != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.goRouteBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _categories.firstWhere(
                      (c) => c.id == _selectedCategory,
                      orElse: () => CategoryModel(id: '', name: _selectedCategory!, icon: '', order: 0),
                    ).name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
        // Top Right: Profile option
        actions: [
          IconButton(
            onPressed: widget.onOpenProfile,
            padding: const EdgeInsets.only(right: 12),
            icon: CircleAvatar(
              radius: 17,
              backgroundColor: AppTheme.borderLight,
              backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                  ? const Icon(Icons.person, size: 20, color: AppTheme.primaryDark)
                  : null,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchPosts(reset: true),
        color: AppTheme.primaryDark,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Search Bar & Filter Indicators
            SliverToBoxAdapter(
              child: Container(
                color: AppTheme.bgSurface,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    // Search text field
                    TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _fetchPosts(reset: true),
                      decoration: InputDecoration(
                        hintText: 'Search posts, services, or locations...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _fetchPosts(reset: true);
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Active Filters indicator row
                    Row(
                      children: [
                        // Sort Badge
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _sortOrder = _sortOrder == 'recent' ? 'distance' : 'recent';
                            });
                            _fetchPosts(reset: true);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _sortOrder == 'distance' ? AppTheme.primaryDark : AppTheme.goRouteBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _sortOrder == 'distance' ? Icons.near_me : Icons.access_time,
                                  size: 13,
                                  color: _sortOrder == 'distance' ? Colors.white : AppTheme.primaryDark,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _sortOrder == 'distance' ? 'Nearest First' : 'Recent First',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _sortOrder == 'distance' ? Colors.white : AppTheme.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        if (_selectedCategory != null) ...[
                          Flexible(
                            child: Chip(
                              label: Text(
                                _categories.firstWhere((c) => c.id == _selectedCategory,
                                    orElse: () => CategoryModel(id: '', name: 'Selected', icon: '', order: 0)).name,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              onDeleted: () {
                                setState(() => _selectedCategory = null);
                                _fetchPosts(reset: true);
                              },
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        const Spacer(),

                        Text(
                          '${_posts.length} posts',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Category Quick Chips Bar
            SliverToBoxAdapter(
              child: Container(
                height: 44,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedCategory == null;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('All'),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryDark,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.primaryDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryDark : AppTheme.borderLight,
                            ),
                          ),
                          onSelected: (_) {
                            setState(() => _selectedCategory = null);
                            _fetchPosts(reset: true);
                          },
                        ),
                      );
                    }

                    final cat = _categories[index - 1];
                    final isSelected = _selectedCategory == cat.id;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryDark,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryDark : AppTheme.borderLight,
                          ),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = isSelected ? null : cat.id;
                          });
                          _fetchPosts(reset: true);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            // Posts List
            if (_isLoading) ...[
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ] else if (_errorMessage != null) ...[
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: AppTheme.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _fetchPosts(reset: true),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_posts.isEmpty) ...[
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 54, color: AppTheme.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'No posts found in this category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Try expanding your distance or selecting another category.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _posts.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return PostCard(post: _posts[index]);
                    },
                    childCount: _posts.length + (_hasMore ? 1 : 0),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
