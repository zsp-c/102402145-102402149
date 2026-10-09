import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';
import 'detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.onBack});

  /// 由 HomePage 注入：作为底部栏 Tab 内嵌时没有可 pop 的路由，
  /// 返回箭头需要切回首页。
  final VoidCallback? onBack;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _history = List.from(AppData.searchHistory);

  /// 当前搜索结果。
  List<ItemModel> _results = [];
  bool _searched = false;
  bool _loading = false;
  String? _error;

  /// 结果筛选 Tab：0 全部 / 1 寻物 / 2 招领。
  int _resultTab = 0;
  static const List<String> _resultTabLabels = ['全部', '寻物', '招领'];
  static const List<String?> _resultTabTypes = [null, ItemType.lost, ItemType.found];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 触发搜索：记录历史 → 调用 `/items/search` → 展示结果。
  Future<void> _doSearch() async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _searched = false;
        _results = [];
      });
      return;
    }
    if (!_history.contains(keyword)) {
      setState(() => _history.insert(0, keyword));
    }
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    try {
      final resp = await ApiService.searchItems(keyword: keyword, pageSize: 50);
      if (!resp.success) {
        setState(() => _error = resp.msg.isEmpty ? '搜索失败' : resp.msg);
        return;
      }
      if (mounted) {
        setState(() {
          _results = resp.data?.records ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<ItemModel> get _filteredResults {
    final t = _resultTabTypes[_resultTab];
    if (t == null) return _results;
    return _results.where((e) => e.type == t).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredResults;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFFF7A2E),
        toolbarHeight: 72,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (widget.onBack != null) {
                  widget.onBack!();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFFFF7A2E), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: '搜索物品 / 地点',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 14),
                        onSubmitted: (_) => _doSearch(),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        setState(() {
                          _searched = false;
                          _results = [];
                        });
                      },
                      child: const Icon(Icons.close, color: Colors.grey, size: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _doSearch,
              child: const Text('搜索',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
      body: _searched ? _buildResults(filtered) : _buildHistory(),
    );
  }

  /// 未搜索时显示历史记录与提示。
  Widget _buildHistory() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF2DB8A3), size: 20),
              const SizedBox(width: 6),
              const Text('搜索历史',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _history.clear()),
                child: const Text('清空', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _history
                .map((k) => GestureDetector(
                      onTap: () {
                        _controller.text = k;
                        _doSearch();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(k, style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: const [
                Icon(Icons.image_search, color: Color(0xFF2DB8A3), size: 36),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('找不到？换个关键词试试',
                          style: TextStyle(color: Color(0xFF2DB8A3), fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('试试搜索「地点 + 物品」组合，例如「体育馆 钥匙」',
                          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
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

  /// 搜索结果列表。
  Widget _buildResults(List<ItemModel> filtered) {
    return Column(
      children: [
        if (_results.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: List.generate(_resultTabLabels.length, (i) {
                final active = _resultTab == i;
                return GestureDetector(
                  onTap: () => setState(() => _resultTab = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFFF7A2E) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: active ? const Color(0xFFFF7A2E) : const Color(0xFFE5E7EB)),
                    ),
                    child: Text('${_resultTabLabels[i]} ${i == 0 ? _results.length : _filteredResults.length}',
                        style: TextStyle(
                            color: active ? Colors.white : const Color(0xFF4B5563),
                            fontSize: 12,
                            fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
                  ),
                );
              }),
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A2E)))
              : _error != null
                  ? _buildErrorView()
                  : filtered.isEmpty
                      ? _buildEmptyView()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _buildResultCard(filtered[index]),
                        ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 52, color: Color(0xFFFF7A2E)),
          const SizedBox(height: 10),
          Text(_error ?? '搜索失败', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _doSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7A2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('重试',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('没有找到相关${_resultTabLabels[_resultTab]}信息',
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildResultCard(ItemModel item) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DetailPage(item: item)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.coverImage,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 72,
                  height: 72,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.typeBgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(item.typeLabel,
                            style: TextStyle(color: item.typeColor, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF9CA3AF), size: 14),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(item.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                      ),
                      Text(item.lostOrFoundTime, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}