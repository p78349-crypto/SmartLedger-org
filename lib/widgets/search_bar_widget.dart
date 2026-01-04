import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_ledger/models/search_filter.dart';
import 'package:smart_ledger/services/search_service.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';

/// 재사용 가능한 검색바 위젯
///
/// 기능:
/// - 카테고리 선택 (드롭다운)
/// - 검색어 입력 (디바운싱)
/// - 카테고리별 힌트 표시
/// - 검색 초기화
class SearchBarWidget extends StatefulWidget {
  final SearchFilter initialFilter;
  final Function(SearchFilter) onSearchChanged;
  final bool autoFocus;
  final Duration debounceDuration;

  const SearchBarWidget({
    super.key,
    required this.onSearchChanged,
    this.initialFilter = const SearchFilter(),
    this.autoFocus = false,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  late SearchCategory _selectedCategory;
  Timer? _debounce;
  final SearchService _searchService = SearchService();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialFilter.query);
    _selectedCategory = widget.initialFilter.category;
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(widget.debounceDuration, () {
      final filter = SearchFilter(category: _selectedCategory, query: query);
      widget.onSearchChanged(filter);
    });
  }

  void _onCategoryChanged(SearchCategory? category) {
    if (category == null) return;

    setState(() {
      _selectedCategory = category;
    });

    // 카테고리 변경 시 즉시 검색 실행
    final filter = SearchFilter(category: category, query: _controller.text);
    widget.onSearchChanged(filter);
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _selectedCategory = SearchCategory.productName;
    });
    widget.onSearchChanged(const SearchFilter());
  }

  String _getCategoryLabel(SearchCategory category) {
    switch (category) {
      case SearchCategory.productName:
        return '제품명';
      case SearchCategory.paymentMethod:
        return '결제수단';
      case SearchCategory.memo:
        return '메모';
      case SearchCategory.amount:
        return '금액';
      case SearchCategory.date:
        return '날짜';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 선택 드롭다운
            Row(
              children: [
                Icon(
                  IconCatalog.filterList,
                  size: 20,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<SearchCategory>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items: SearchCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(_getCategoryLabel(category)),
                        );
                      }).toList(),
                      onChanged: _onCategoryChanged,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // 검색어 입력 필드
            TextField(
              controller: _controller,
              autofocus: widget.autoFocus,
              decoration: InputDecoration(
                hintText: _searchService.getSearchHint(_selectedCategory),
                prefixIcon: const Icon(IconCatalog.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(IconCatalog.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// 간단한 검색바 (한 줄 버전)
class CompactSearchBar extends StatelessWidget {
  final SearchFilter filter;
  final Function(SearchFilter) onSearchChanged;

  const CompactSearchBar({
    super.key,
    required this.filter,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: '검색...',
        prefixIcon: const Icon(IconCatalog.search),
        suffixIcon: filter.isNotEmpty
            ? IconButton(
                icon: const Icon(IconCatalog.clear),
                onPressed: () => onSearchChanged(const SearchFilter()),
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      onChanged: (query) {
        onSearchChanged(SearchFilter(query: query));
      },
    );
  }
}
