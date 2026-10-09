import 'package:flutter/material.dart';
import '../data/app_data.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';
import '../services/search_history_api.dart';
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

  /// 结果分页：滚到底部自动加载下一页。
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 10;
  int _pageNum = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  int _total = 0;

  /// 搜索历史最多展示条数。
  static const int _historyMax = 10;

  /// 结果筛选 Tab：0 全部 / 1 寻物 / 2 招领。
  int _resultTab = 0;
  static const List<String> _resultTabLabels = ['全部', '寻物', '招领'];
  static const List<String?> _resultTabTypes = [null, ItemType.lost, ItemType.found];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 搜索历史以后端为准，后端不可用时退回本地兜底数据
    _loadHistory();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// 滚动到距底部 200 像素时预加载下一页。
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  /// 拉取当前用户的搜索历史（`GET /search/history`）。
  Future<void> _loadHistory() async {
    try {
      final resp = await SearchHistoryApi.fetchHistory(limit: _historyMax);
      final data = resp.data;
      if (resp.success && data != null && mounted) {
        setState(() {
          _history
            ..clear()
            ..addAll(data);
        });
      }
    } catch (_) {
      // 后端未启动时保留本地兜底数据，不影响页面展示
    }
  }

  /// 本地先回显历史，再异步同步到后端。
  void _addHistoryLocal(String keyword) {
    setState(() {
      _history.remove(keyword);
      _history.insert(0, keyword);
      if (_history.length > _historyMax) {
        _history.removeRange(_historyMax, _history.length);
      }
    });
    _syncRecordHistory(keyword);
  }

  /// 上报搜索关键词，失败不打断搜索主流程。
  Future<void> _syncRecordHistory(String keyword) async {
    try {
      await SearchHistoryApi.recordHistory(keyword);
    } catch (_) {
      // 记录历史失败不影响搜索结果展示
    }
  }

  /// 清空历史：本地立即清空，同时通知后端（`DELETE /search/history`）。
  Future<void> _clearHistory() async {
    setState(() => _history.clear());
    try {
      await SearchHistoryApi.clearHistory();
    } catch (_) {
      // 后端不可用时仅清空本地
    }
  }

  /// 触发搜索：记录历史 → 调用 `/items/search` 第 1 页 → 展示结果。
  /// 后续页由 _loadMore 在滚动到底部时追加。
  ///
  /// [recordHistory] 为 false 时只重新查询、不重复上报搜索历史
  /// （切换结果页签属于换筛选条件，不是一次新的搜索行为）。
  Future<void> _doSearch({bool recordHistory = true}) async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _searched = false;
        _results = [];
        _total = 0;
        _hasMore = true;
      });
      return;
    }
    if (recordHistory) _addHistoryLocal(keyword);
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
      _pageNum = 1;
      _hasMore = true;
      _total = 0;
    });
    try {
      final resp = await ApiService.searchItems(
        keyword: keyword,
        type: _resultTabTypes[_resultTab],
        pageNum: 1,
        pageSize: _pageSize,
      );
      if (!resp.success) {
        if (mounted) {
          setState(() => _error = resp.msg.isEmpty ? '搜索失败' : resp.msg);
        }
        return;
      }
      if (mounted) {
        final records = resp.data?.records ?? <ItemModel>[];
        final total = resp.data?.total ?? records.length;
        setState(() {
          _results = records;
          _total = total;
          _pageNum = 1;
          _hasMore = records.isNotEmpty && records.length < total;
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

  /// 加载下一页并追加到结果列表（滚动触底时调用）。
  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore || !_searched) return;
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) return;

    setState(() => _loadingMore = true);
    try {
      final next = _pageNum + 1;
      final resp = await ApiService.searchItems(
        keyword: keyword,
        type: _resultTabTypes[_resultTab],
        pageNum: next,
        pageSize: _pageSize,
      );
      if (!resp.success) {
        if (mounted) setState(() => _loadingMore = false);
        return;
      }
      if (mounted) {
        final more = resp.data?.records ?? <ItemModel>[];
        final total = resp.data?.total ?? _total;
        setState(() {
          _results = [..._results, ...more];
          _pageNum = next;
          _total = total;
          _hasMore = more.isNotEmpty && _results.length < total;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// 切换结果页签：换筛选条件后带 type 重新从第 1 页查询。
  /// 筛选在服务端完成，所以「共 N 条」始终是当前条件下的总数。
  void _switchResultTab(int index) {
    if (_resultTab == index) return;
    setState(() => _resultTab = index);
    _doSearch(recordHistory: false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _results;
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
                          _total = 0;
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
                onTap: _clearHistory,
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
        // 页签在搜索后始终显示：某个筛选条件下可能 0 条，
        // 若跟着结果一起隐藏，就没法切回其他页签了。
        if (_searched)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: List.generate(_resultTabLabels.length, (i) {
                      final active = _resultTab == i;
                      return GestureDetector(
                        onTap: () => _switchResultTab(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFFFF7A2E) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: active ? const Color(0xFFFF7A2E) : const Color(0xFFE5E7EB)),
                          ),
                          child: Text(_resultTabLabels[i],
                              style: TextStyle(
                                  color: active ? Colors.white : const Color(0xFF4B5563),
                                  fontSize: 12,
                                  fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Text('共 $_total 条', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              ],
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
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length + 1,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index >= filtered.length) {
                              return _buildListFooter(filtered.length);
                            }
                            return _buildResultCard(filtered[index]);
                          },
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

  /// 列表底部：加载下一页时显示转圈，全部加载完显示「没有更多了」。
  Widget _buildListFooter(int shown) {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF7A2E)),
          ),
        ),
      );
    }
    if (!_hasMore && shown > 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('没有更多了', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
        ),
      );
    }
    return const SizedBox(height: 8);
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