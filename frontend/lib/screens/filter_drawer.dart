import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../theme/app_theme.dart';

class FilterDrawer extends StatefulWidget {
  final List<CategoryModel> categories;
  final String? selectedCategory;
  final String sortOrder; // 'recent' or 'distance'
  final double? maxDistance;
  final Function({
    required String? category,
    required String sortOrder,
    required double? maxDistance,
  }) onApply;

  const FilterDrawer({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.sortOrder,
    required this.maxDistance,
    required this.onApply,
  });

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  late String? _selectedCat;
  late String _sortOrder;
  late double? _maxDist;

  @override
  void initState() {
    super.initState();
    _selectedCat = widget.selectedCategory;
    _sortOrder = widget.sortOrder;
    _maxDist = widget.maxDistance;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Categories & Filter',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.goRouteBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppTheme.primaryDark),
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),

            // Filter Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Distance Sorting
                  const Text(
                    'Sorting Order',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Recent'),
                          selected: _sortOrder == 'recent',
                          selectedColor: AppTheme.primaryDark,
                          labelStyle: TextStyle(
                            color: _sortOrder == 'recent' ? Colors.white : AppTheme.primaryDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _sortOrder = 'recent');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Nearest First'),
                          selected: _sortOrder == 'distance',
                          selectedColor: AppTheme.primaryDark,
                          labelStyle: TextStyle(
                            color: _sortOrder == 'distance' ? Colors.white : AppTheme.primaryDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _sortOrder = 'distance');
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Distance Filter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Max Distance',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        _maxDist == null ? 'Any Distance' : '< ${_maxDist!.round()} km',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accentBlue,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _maxDist ?? 50.0,
                    min: 5.0,
                    max: 100.0,
                    divisions: 19,
                    activeColor: AppTheme.primaryDark,
                    label: '${(_maxDist ?? 50).round()} km',
                    onChanged: (val) {
                      setState(() => _maxDist = val);
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _maxDist = null),
                      child: const Text('Remove distance limit', style: TextStyle(fontSize: 11)),
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    'Select Category',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // "All Categories" item
                  _buildCategoryTile(
                    title: 'All Categories',
                    isSelected: _selectedCat == null,
                    count: null,
                    onTap: () => setState(() => _selectedCat = null),
                  ),

                  // Dynamic categories list
                  ...widget.categories.map((cat) {
                    final isSelected = _selectedCat == cat.id;
                    return _buildCategoryTile(
                      title: cat.name,
                      isSelected: isSelected,
                      count: cat.postsCount,
                      onTap: () => setState(() => _selectedCat = cat.id),
                    );
                  }),
                ],
              ),
            ),

            // Bottom Apply / Clear buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: AppTheme.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedCat = null;
                          _sortOrder = 'recent';
                          _maxDist = null;
                        });
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        widget.onApply(
                          category: _selectedCat,
                          sortOrder: _sortOrder,
                          maxDistance: _maxDist,
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontWeight: FontWeight.w600),
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
  }

  Widget _buildCategoryTile({
    required String title,
    required bool isSelected,
    required int? count,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected ? AppTheme.goRouteBg : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
            ),
          ),
        trailing: count != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppTheme.goRouteBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              )
            : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
